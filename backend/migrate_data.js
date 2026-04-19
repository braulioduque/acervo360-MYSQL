const { createClient } = require('@supabase/supabase-js');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
};

async function downloadFileFromStorage(bucket, pathOnSupabase, localFilePath) {
  if (!pathOnSupabase) return;
  
  const dir = path.dirname(localFilePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  try {
    const { data, error } = await supabase.storage.from(bucket).download(pathOnSupabase);
    if (error) throw error;
    
    const buffer = Buffer.from(await data.arrayBuffer());
    fs.writeFileSync(localFilePath, buffer);
    console.log(`  ✅ [${bucket}] Baixado com sucesso: ${pathOnSupabase}`);
  } catch (err) {
    console.error(`  ❌ [${bucket}] Erro ao baixar ${pathOnSupabase}:`, err.message);
  }
}

async function migrate() {
  console.log('🚀 Iniciando migração de dados com paridade total...');
  const pool = await mysql.createPool(dbConfig);
  const defaultPassword = 'Mudar@123';
  const hashedPass = await bcrypt.hash(defaultPassword, 10);

  try {
    // 0. Mapear E-mails do Auth (Supabase Auth.Users não é acessível via .from('users'))
    console.log('🔑 Buscando e-mails do Supabase Auth...');
    const { data: { users: authUsers }, error: authError } = await supabase.auth.admin.listUsers();
    const emailMap = {};
    if (!authError && authUsers) {
      authUsers.forEach(u => emailMap[u.id] = u.email);
    }

    // 1. Planos de Assinatura
    console.log('📦 Migrando subscription_plans...');
    const { data: plans } = await supabase.from('subscription_plans').select('*');
    for (const p of (plans || [])) {
      await pool.query(
        `INSERT INTO subscription_plans (id, plan_key, title, price, period_label, months_count, subtitle_override, badge, is_recommended, icon_name, sort_order, active, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         plan_key=VALUES(plan_key), title=VALUES(title), price=VALUES(price), period_label=VALUES(period_label), months_count=VALUES(months_count), subtitle_override=VALUES(subtitle_override), badge=VALUES(badge), is_recommended=VALUES(is_recommended), icon_name=VALUES(icon_name), sort_order=VALUES(sort_order), active=VALUES(active)`,
        [p.id, p.plan_key, p.title, p.price, p.period_label, p.months_count, p.subtitle_override, p.badge, p.is_recommended ? 1 : 0, p.icon_name, p.sort_order, p.active ? 1 : 0, p.created_at]
      );
    }

    // 2. Modalidades
    console.log('🎯 Migrando habituality_modalities...');
    const { data: modalities } = await supabase.from('habituality_modalities').select('*');
    for (const m of (modalities || [])) {
      await pool.query(
        'INSERT IGNORE INTO habituality_modalities (id, name, active, created_at) VALUES (?, ?, ?, ?)',
        [m.id, m.name, m.active ? 1 : 0, m.created_at]
      );
    }

    // 3. Perfis (Profiles)
    console.log('👥 Migrando profiles...');
    const { data: profiles } = await supabase.from('profiles').select('*');
    for (const pr of (profiles || [])) {
      const userEmail = emailMap[pr.id] || pr.email || `user_${pr.id.substring(0,8)}@auto.migrated`;
      try {
        await pool.query(
          `INSERT INTO profiles (id, email, password_hash, full_name, cpf, phone, cr_number, cr_categories, cr_valid_until, avatar_url, cr_url, is_admin, created_at) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
           ON DUPLICATE KEY UPDATE 
           email=VALUES(email), full_name=VALUES(full_name), cpf=VALUES(cpf), phone=VALUES(phone), cr_number=VALUES(cr_number), cr_categories=VALUES(cr_categories), cr_valid_until=VALUES(cr_valid_until), avatar_url=VALUES(avatar_url), cr_url=VALUES(cr_url), is_admin=VALUES(is_admin)`,
          [pr.id, userEmail, hashedPass, pr.full_name, pr.cpf, pr.phone, pr.cr_number, JSON.stringify(pr.cr_categories), pr.cr_valid_until, pr.avatar_url, pr.cr_url, pr.is_admin, pr.created_at]
        );
      } catch (e) {
        console.error(`  ❌ Erro ao importar usuário ${userEmail}:`, e.message);
      }
      
      if (pr.avatar_url) await downloadFileFromStorage('profile-avatars', pr.avatar_url, path.join(__dirname, 'uploads', pr.avatar_url));
      if (pr.cr_url) await downloadFileFromStorage('cr-documents', pr.cr_url, path.join(__dirname, 'uploads', pr.cr_url));
    }

    // 4. Endereços
    console.log('🏠 Migrando profile_addresses...');
    const { data: addrs } = await supabase.from('profile_addresses').select('*');
    for (const a of (addrs || [])) {
      await pool.query(
        `INSERT INTO profile_addresses (id, user_id, address_type, street, number, complement, neighborhood, state_code, city, postal_code, created_at, updated_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         user_id=VALUES(user_id), address_type=VALUES(address_type), street=VALUES(street), number=VALUES(number), complement=VALUES(complement), neighborhood=VALUES(neighborhood), state_code=VALUES(state_code), city=VALUES(city), postal_code=VALUES(postal_code)`,
        [a.id, a.user_id, a.address_type, a.street, a.number, a.complement, a.neighborhood, a.state_code, a.city, a.postal_code, a.created_at, a.updated_at]
      );
    }

    // 5. Clubes
    console.log('🛡️ Migrando clubs...');
    const { data: clubs } = await supabase.from('clubs').select('*');
    for (const c of (clubs || [])) {
      await pool.query(
        `INSERT INTO clubs (id, owner_user_id, name, document_number, city, state, cr_number, street, number, complement, neighborhood, logo_url, phone, cnpj, status, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         owner_user_id=VALUES(owner_user_id), name=VALUES(name), document_number=VALUES(document_number), city=VALUES(city), state=VALUES(state), cr_number=VALUES(cr_number), street=VALUES(street), number=VALUES(number), complement=VALUES(complement), neighborhood=VALUES(neighborhood), logo_url=VALUES(logo_url), phone=VALUES(phone), cnpj=VALUES(cnpj), status=VALUES(status)`,
        [c.id, c.owner_user_id, c.name, c.document_number, c.city, c.state, c.cr_number, c.street, c.number, c.complement, c.neighborhood, c.logo_url, c.phone, c.cnpj, c.status, c.created_at]
      );
      if (c.logo_url) await downloadFileFromStorage('club-avatars', c.logo_url, path.join(__dirname, 'uploads', c.logo_url));
    }

    // 6. Armas
    console.log('🔫 Migrando firearms...');
    const { data: guns } = await supabase.from('firearms').select('*');
    for (const g of (guns || [])) {
      await pool.query(
        `INSERT INTO firearms (id, owner_user_id, brand, model, caliber, sigma_number, craf_number, craf_valid_until, avatar_url, craf_url, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         owner_user_id=VALUES(owner_user_id), brand=VALUES(brand), model=VALUES(model), caliber=VALUES(caliber), sigma_number=VALUES(sigma_number), craf_number=VALUES(craf_number), craf_valid_until=VALUES(craf_valid_until), avatar_url=VALUES(avatar_url), craf_url=VALUES(craf_url)`,
        [g.id, g.owner_user_id, g.brand, g.model, g.caliber, g.sigma_number, g.craf_number, g.craf_valid_until, g.avatar_url, g.craf_url, g.created_at]
      );
      if (g.avatar_url) await downloadFileFromStorage('firearm-avatars', g.avatar_url, path.join(__dirname, 'uploads', g.avatar_url));
      if (g.craf_url) await downloadFileFromStorage('craf-documents', g.craf_url, path.join(__dirname, 'uploads', g.craf_url));
    }

    // 7. Habitualidades
    console.log('📝 Migrando habitualities...');
    const { data: habs } = await supabase.from('habitualities').select('*');
    for (const h of (habs || [])) {
      await pool.query(
        `INSERT INTO habitualities (id, owner_user_id, type, event_name, modality, modality_other, date_realization, start_time, end_time, club_id, location_name, equipment_source, firearm_id, third_party_type, third_party_brand, third_party_species, third_party_caliber_type, third_party_caliber, ammo_source, shot_count, attachment_url, book_page, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         owner_user_id=VALUES(owner_user_id), type=VALUES(type), event_name=VALUES(event_name), modality=VALUES(modality), modality_other=VALUES(modality_other), date_realization=VALUES(date_realization), start_time=VALUES(start_time), end_time=VALUES(end_time), club_id=VALUES(club_id), location_name=VALUES(location_name), equipment_source=VALUES(equipment_source), firearm_id=VALUES(firearm_id), third_party_type=VALUES(third_party_type), third_party_brand=VALUES(third_party_brand), third_party_species=VALUES(third_party_species), third_party_caliber_type=VALUES(third_party_caliber_type), third_party_caliber=VALUES(third_party_caliber), ammo_source=VALUES(ammo_source), shot_count=VALUES(shot_count), attachment_url=VALUES(attachment_url), book_page=VALUES(book_page)`,
        [h.id, h.owner_user_id, h.type, h.event_name, h.modality, h.modality_other, h.date_realization, h.start_time, h.end_time, h.club_id, h.location_name, h.equipment_source, h.firearm_id, h.third_party_type, h.third_party_brand, h.third_party_species, h.third_party_caliber_type, h.third_party_caliber, h.ammo_source, h.shot_count, h.attachment_url, h.book_page, h.created_at]
      );
      if (h.attachment_url) await downloadFileFromStorage('habitualities', h.attachment_url, path.join(__dirname, 'uploads', h.attachment_url));
    }

    // 8. GTes
    console.log('📄 Migrando GTes...');
    const { data: gtes } = await supabase.from('gtes').select('*');
    for (const g of (gtes || [])) {
      await pool.query(
        `INSERT INTO gtes (id, owner_user_id, firearm_id, profile_address_id, destination_club_id, protocol_number, issued_at, expires_at, status, notes, gte_url, created_at) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         owner_user_id=VALUES(owner_user_id), firearm_id=VALUES(firearm_id), profile_address_id=VALUES(profile_address_id), destination_club_id=VALUES(destination_club_id), protocol_number=VALUES(protocol_number), issued_at=VALUES(issued_at), expires_at=VALUES(expires_at), status=VALUES(status), notes=VALUES(notes), gte_url=VALUES(gte_url)`,
        [g.id, g.owner_user_id, g.firearm_id, g.profile_address_id, g.destination_club_id, g.protocol_number, g.issued_at, g.expires_at, g.status, g.notes, g.gte_url, g.created_at]
      );
      if (g.gte_url) await downloadFileFromStorage('gte-documents', g.gte_url, path.join(__dirname, 'uploads', g.gte_url));
    }

    // 9. Assinaturas de Usuários
    console.log('💳 Migrando user_subscriptions...');
    const { data: subs } = await supabase.from('user_subscriptions').select('*');
    for (const s of (subs || [])) {
      await pool.query(
        `INSERT INTO user_subscriptions (id, user_id, plan, start_date, end_date, status) 
         VALUES (?, ?, ?, ?, ?, ?) 
         ON DUPLICATE KEY UPDATE 
         user_id=VALUES(user_id), plan=VALUES(plan), start_date=VALUES(start_date), end_date=VALUES(end_date), status=VALUES(status)`,
        [s.id, s.user_id, s.plan, s.start_date, s.end_date, s.status]
      );
    }

    // 10. Associações Usuários-Clubes
    console.log('🔗 Migrando user_clubs...');
    const { data: userClubs } = await supabase.from('user_clubs').select('*');
    for (const uc of (userClubs || [])) {
      await pool.query(
        'INSERT IGNORE INTO user_clubs (id, user_id, club_id, created_at) VALUES (?, ?, ?, ?)',
        [uc.id, uc.user_id, uc.club_id, uc.created_at]
      );
    }

    console.log('✨ Migração completa com paridade total concluída!');
  } catch (err) {
    console.error('❌ Erro crítico durante a migração:', err);
  } finally {
    await pool.end();
  }
}

migrate();
