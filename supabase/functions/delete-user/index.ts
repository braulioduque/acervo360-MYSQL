import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type RequestMeta = {
  requestId: string;
  ipAddress: string | null;
  userAgent: string | null;
};

const json = (status: number, body: Record<string, unknown>, extraHeaders: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      ...extraHeaders,
    },
  });

const parsePositiveInt = (value: string | undefined, fallbackValue: number): number => {
  if (!value) return fallbackValue;
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed) || parsed <= 0) return fallbackValue;
  return parsed;
};

const getMeta = (req: Request): RequestMeta => {
  const requestId =
    req.headers.get('x-request-id') ??
    req.headers.get('cf-ray') ??
    (globalThis.crypto?.randomUUID?.() ?? `req-${Date.now()}`);

  const forwardedFor = req.headers.get('x-forwarded-for');
  const ipAddress = forwardedFor?.split(',')[0]?.trim() || req.headers.get('x-real-ip');

  return {
    requestId,
    ipAddress: ipAddress ?? null,
    userAgent: req.headers.get('user-agent'),
  };
};

const writeAuditLog = async (
  supabaseAdmin: ReturnType<typeof createClient>,
  payload: {
    eventType: string;
    success: boolean;
    userId?: string | null;
    meta: RequestMeta;
    details?: Record<string, unknown>;
  },
) => {
  await supabaseAdmin.from('security_audit_logs').insert({
    event_type: payload.eventType,
    success: payload.success,
    user_id: payload.userId ?? null,
    request_id: payload.meta.requestId,
    ip_address: payload.meta.ipAddress,
    user_agent: payload.meta.userAgent,
    details: payload.details ?? {},
  });
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const meta = getMeta(req);
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const rateLimitMax = parsePositiveInt(Deno.env.get('DELETE_USER_RATE_LIMIT_MAX'), 3);
  const rateLimitWindowMinutes = parsePositiveInt(Deno.env.get('DELETE_USER_RATE_LIMIT_WINDOW_MINUTES'), 60);

  if (!supabaseUrl || !serviceRoleKey) {
    return json(500, { error: 'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY' });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return json(401, { error: 'Missing Authorization header' });
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) {
    await writeAuditLog(supabaseAdmin, {
      eventType: 'delete_user_denied',
      success: false,
      meta,
      details: { reason: 'empty_bearer_token' },
    });
    return json(401, { error: 'Invalid bearer token' });
  }

  const {
    data: { user },
    error: userError,
  } = await supabaseAdmin.auth.getUser(token);

  if (userError || !user) {
    await writeAuditLog(supabaseAdmin, {
      eventType: 'delete_user_denied',
      success: false,
      meta,
      details: { reason: 'unauthorized', error: userError?.message ?? null },
    });
    return json(401, { error: 'Unauthorized' });
  }

  const windowStart = new Date(Date.now() - rateLimitWindowMinutes * 60 * 1000).toISOString();
  const { count, error: countError } = await supabaseAdmin
    .from('security_audit_logs')
    .select('id', { count: 'exact', head: true })
    .eq('event_type', 'delete_user_attempt')
    .eq('user_id', user.id)
    .gte('created_at', windowStart);

  if (countError) {
    await writeAuditLog(supabaseAdmin, {
      eventType: 'delete_user_denied',
      success: false,
      userId: user.id,
      meta,
      details: { reason: 'rate_limit_count_failed', error: countError.message },
    });
    return json(500, { error: 'Failed to evaluate rate limit' });
  }

  if ((count ?? 0) >= rateLimitMax) {
    await writeAuditLog(supabaseAdmin, {
      eventType: 'delete_user_attempt',
      success: false,
      userId: user.id,
      meta,
      details: {
        status: 'blocked_rate_limit',
        windowMinutes: rateLimitWindowMinutes,
        maxAttempts: rateLimitMax,
      },
    });

    return json(
      429,
      { error: 'Too many deletion attempts. Try again later.' },
      { 'Retry-After': String(rateLimitWindowMinutes * 60) },
    );
  }

  const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id);

  if (deleteError) {
    await writeAuditLog(supabaseAdmin, {
      eventType: 'delete_user_attempt',
      success: false,
      userId: user.id,
      meta,
      details: {
        status: 'delete_failed',
        error: deleteError.message,
      },
    });

    return json(500, { error: deleteError.message });
  }

  await writeAuditLog(supabaseAdmin, {
    eventType: 'delete_user_attempt',
    success: true,
    userId: user.id,
    meta,
    details: {
      status: 'deleted',
      rateLimitWindowMinutes,
      rateLimitMax,
    },
  });

  return json(200, { success: true, deletedUserId: user.id, requestId: meta.requestId });
});
