-- Migration for Habitualidades functionality

-- Modalidades de habitualidade
CREATE TABLE IF NOT EXISTS public.habituality_modalities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Popular modalidades padrão
INSERT INTO public.habituality_modalities (name) VALUES
('IPSC'),
('IDSC'),
('Tiro de Precisão'),
('Tiro Prático'),
('Tiro ao Prato'),
('Outros')
ON CONFLICT (name) DO NOTHING;

-- Tabela Geral de Clubes (para busca global)
CREATE TABLE IF NOT EXISTS public.global_clubs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    cnpj text,
    city text,
    state text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Tabela de Habitualidades
CREATE TABLE IF NOT EXISTS public.habitualities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Tipo e Evento
    type text NOT NULL CHECK (type IN ('Treino', 'Competição', 'Curso')),
    event_name text, -- Preenchido se for Competição ou Curso
    
    -- Modalidade
    modality text NOT NULL,
    modality_other text, -- Preenchido se modalidade for 'Outros'
    
    -- Data e Hora
    date_realization date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    
    -- Localização
    club_id uuid REFERENCES public.clubs(id) ON DELETE SET NULL,
    location_name text NOT NULL, -- Nome do clube/local digitado ou selecionado
    
    -- Equipamento
    equipment_source text NOT NULL CHECK (equipment_source IN ('Própria', 'Terceiros')),
    firearm_id uuid REFERENCES public.firearms(id) ON DELETE SET NULL,
    
    -- Detalhes de equipamento de terceiros
    third_party_type text CHECK (third_party_type IN ('Sigma', 'Sinarm')),
    third_party_brand text,
    third_party_species text CHECK (third_party_species IN ('Pistola', 'Revolver', 'Espingarda', 'Carabina / Fuzil', 'Rifle / Fuzil', 'Outros')),
    third_party_caliber_type text CHECK (third_party_caliber_type IN ('Restrito', 'Permitido')),
    third_party_caliber text,
    
    -- Munição e Disparos
    ammo_source text NOT NULL CHECK (ammo_source IN ('Própria', 'Terceirizada')),
    shot_count integer NOT NULL,
    
    -- Anexo
    attachment_url text,
    
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.habituality_modalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.global_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habitualities ENABLE ROW LEVEL SECURITY;

-- Políticas de Acesso
CREATE POLICY "modalities_select_all" ON public.habituality_modalities FOR SELECT USING (true);
CREATE POLICY "global_clubs_select_all" ON public.global_clubs FOR SELECT USING (true);
CREATE POLICY "habitualities_all_own" ON public.habitualities 
    FOR ALL USING (auth.uid() = owner_user_id) 
    WITH CHECK (auth.uid() = owner_user_id);

-- Trigger para updated_at
CREATE TRIGGER trg_habitualities_updated_at
BEFORE UPDATE ON public.habitualities
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
