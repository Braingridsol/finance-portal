-- ============================================================================
-- Finance Portal — Supabase Schema (Sprint 4)
-- ============================================================================
-- USAGE:
-- 1. Create a Supabase project at https://supabase.com (free tier is fine)
-- 2. Once provisioned, open SQL Editor in Supabase dashboard
-- 3. Paste this entire file and click "Run"
-- 4. Verify all tables show up under Database → Tables
-- 5. Copy "Project URL" and "anon public" key from Project Settings → API
-- 6. Paste them into the Finance Portal app's first-time setup
-- ============================================================================

-- ============================================================================
-- PROFILES — Tally-style. One user → many isolated profiles.
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'Personal',
  currency    TEXT DEFAULT '₹',
  color       TEXT,
  icon        TEXT,
  is_default  BOOLEAN DEFAULT false,
  archived    BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles(user_id);

-- ============================================================================
-- SETTINGS — one record per profile
-- ============================================================================
CREATE TABLE IF NOT EXISTS settings (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id               UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  currency                 TEXT DEFAULT '₹',
  theme                    TEXT DEFAULT 'light',
  projection_days          INTEGER DEFAULT 60,
  fy_start_month           INTEGER DEFAULT 4,
  retirement_age           INTEGER DEFAULT 60,
  inflation_rate           NUMERIC(5,2) DEFAULT 6.0,
  equity_benchmark_return  NUMERIC(5,2) DEFAULT 12.0,
  card_min_payment_pct     NUMERIC(5,2) DEFAULT 5.0,
  rounding_decimals        INTEGER DEFAULT 0,
  date_format              TEXT DEFAULT 'DD MMM YYYY',
  updated_at               TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- CATEGORIES + SUBCATEGORIES
-- ============================================================================
CREATE TABLE IF NOT EXISTS categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL CHECK (kind IN ('income','expense')),
  name          TEXT NOT NULL,
  icon          TEXT,
  color         TEXT,
  essential     BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, kind, name)
);

CREATE TABLE IF NOT EXISTS subcategories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category_id   UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(category_id, name)
);

-- ============================================================================
-- TAX FLAGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS tax_flags (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  updated_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, name)
);

-- ============================================================================
-- PEOPLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS people (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  relationship TEXT,
  dob          DATE,
  pan          TEXT,
  notes        TEXT,
  updated_at   TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ACCOUNTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS accounts (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name               TEXT NOT NULL,
  bank               TEXT,
  type               TEXT NOT NULL,
  status             TEXT NOT NULL DEFAULT 'Active',
  last4              TEXT,
  balance            NUMERIC(15,2) DEFAULT 0,
  min_balance        NUMERIC(15,2) DEFAULT 0,
  min_balance_type   TEXT DEFAULT 'None',
  interest_rate      NUMERIC(6,3) DEFAULT 0,
  interest_payout    TEXT,
  ifsc               TEXT,
  opening_date       DATE,
  maturity_date      DATE,
  maturity_amount    NUMERIC(15,2),
  joint_holder       TEXT,
  nominee            TEXT,
  notes              TEXT,
  updated_at         TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_accounts_profile ON accounts(profile_id);

-- ============================================================================
-- CARDS
-- ============================================================================
CREATE TABLE IF NOT EXISTS cards (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id             UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name                   TEXT NOT NULL,
  bank                   TEXT,
  network                TEXT,
  status                 TEXT NOT NULL DEFAULT 'Active',
  last4                  TEXT,
  credit_limit           NUMERIC(15,2) DEFAULT 0,
  interest_rate          NUMERIC(6,3) DEFAULT 0,
  bill_day               INTEGER CHECK (bill_day BETWEEN 1 AND 31),
  due_day                INTEGER CHECK (due_day BETWEEN 1 AND 31),
  annual_fee             NUMERIC(10,2) DEFAULT 0,
  waiver                 TEXT,
  reward_type            TEXT,
  reward_rate            NUMERIC(6,3) DEFAULT 0,
  auto_debit_account_id  UUID REFERENCES accounts(id) ON DELETE SET NULL,
  notes                  TEXT,
  updated_at             TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cards_profile ON cards(profile_id);

-- ============================================================================
-- LOANS
-- ============================================================================
CREATE TABLE IF NOT EXISTS loans (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id                 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name                       TEXT NOT NULL,
  lender                     TEXT,
  type                       TEXT,
  status                     TEXT NOT NULL DEFAULT 'Active',
  last4                      TEXT,
  sanctioned_amount          NUMERIC(15,2),
  outstanding                NUMERIC(15,2),
  original_emi               NUMERIC(12,2),
  current_emi                NUMERIC(12,2),
  emi_day                    INTEGER,
  original_rate              NUMERIC(6,3),
  current_rate               NUMERIC(6,3),
  rate_type                  TEXT,
  disbursement_date          DATE,
  original_tenure_months     INTEGER,
  current_tenure_remaining   INTEGER,
  paid_from_account_id       UUID REFERENCES accounts(id) ON DELETE SET NULL,
  processing_fee             NUMERIC(12,2) DEFAULT 0,
  other_charges              NUMERIC(12,2) DEFAULT 0,
  notes                      TEXT,
  updated_at                 TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_loans_profile ON loans(profile_id);

-- ============================================================================
-- LOAN EVENTS (history of every change to a loan)
-- ============================================================================
CREATE TABLE IF NOT EXISTS loan_events (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  loan_id              UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  date                 DATE NOT NULL,
  event_type           TEXT NOT NULL,
  amount               NUMERIC(15,2),
  from_account_id      UUID REFERENCES accounts(id) ON DELETE SET NULL,
  principal_component  NUMERIC(15,2),
  interest_component   NUMERIC(15,2),
  balance_after        NUMERIC(15,2),
  old_value            NUMERIC(12,3),
  new_value            NUMERIC(12,3),
  strategy             TEXT,
  note                 TEXT,
  created_at           TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_loan_events_loan_date ON loan_events(loan_id, date);

-- ============================================================================
-- INSURANCE (insured persons stored as array; simpler than join table for personal use)
-- ============================================================================
CREATE TABLE IF NOT EXISTS insurance (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  insurer               TEXT,
  type                  TEXT,
  status                TEXT DEFAULT 'Active',
  policy_last4          TEXT,
  premium               NUMERIC(12,2),
  frequency             TEXT,
  cover                 NUMERIC(15,2),
  renewal_date          DATE,
  start_date            DATE,
  end_date              DATE,
  insured_person_ids    UUID[] DEFAULT '{}',
  paid_from_account_id  UUID REFERENCES accounts(id) ON DELETE SET NULL,
  nominee               TEXT,
  agent                 TEXT,
  agent_contact         TEXT,
  notes                 TEXT,
  updated_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_insurance_profile ON insurance(profile_id);

-- ============================================================================
-- INVESTMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS investments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  provider              TEXT,
  type                  TEXT,
  status                TEXT DEFAULT 'Active',
  folio                 TEXT,
  invested              NUMERIC(15,2),
  current_value         NUMERIC(15,2),
  sip_amount            NUMERIC(12,2),
  sip_day               INTEGER,
  paid_from_account_id  UUID REFERENCES accounts(id) ON DELETE SET NULL,
  start_date            DATE,
  maturity_date         DATE,
  tax_benefit           TEXT,
  units                 NUMERIC(20,4),
  purpose               TEXT,
  asset_class           TEXT,
  notes                 TEXT,
  updated_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_investments_profile ON investments(profile_id);

-- ============================================================================
-- RECURRING TEMPLATES
-- ============================================================================
CREATE TABLE IF NOT EXISTS recurring (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label                 TEXT NOT NULL,
  type                  TEXT NOT NULL,
  amount                NUMERIC(15,2),
  category              TEXT,
  frequency             TEXT,
  day_of_month          INTEGER,
  month                 INTEGER,
  from_account_id       UUID REFERENCES accounts(id) ON DELETE SET NULL,
  to_account_id         UUID REFERENCES accounts(id) ON DELETE SET NULL,
  card_id               UUID REFERENCES cards(id) ON DELETE SET NULL,
  start_date            DATE,
  end_date              DATE,
  active                BOOLEAN DEFAULT true,
  auto_create_drafts    BOOLEAN DEFAULT true,
  draft_advance_months  INTEGER DEFAULT 3,
  updated_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_recurring_profile ON recurring(profile_id);

-- ============================================================================
-- TRANSACTIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type              TEXT NOT NULL CHECK (type IN ('income','expense','settlement','transfer')),
  status            TEXT NOT NULL DEFAULT 'Settled' CHECK (status IN ('Draft','Settled')),
  source            TEXT NOT NULL DEFAULT 'Manual',
  date              DATE NOT NULL,
  amount            NUMERIC(15,2) NOT NULL,
  category          TEXT,
  subcategory       TEXT,
  from_account_id   UUID REFERENCES accounts(id) ON DELETE SET NULL,
  to_account_id     UUID REFERENCES accounts(id) ON DELETE SET NULL,
  card_id           UUID REFERENCES cards(id) ON DELETE SET NULL,
  loan_id           UUID REFERENCES loans(id) ON DELETE SET NULL,
  insurance_id      UUID REFERENCES insurance(id) ON DELETE SET NULL,
  recurring_id      UUID REFERENCES recurring(id) ON DELETE SET NULL,
  payee             TEXT,
  mode              TEXT,
  reference         TEXT,
  tax_flag          TEXT,
  note              TEXT,
  draft_created_at  TIMESTAMPTZ DEFAULT now(),
  settled_at        TIMESTAMPTZ,
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_txn_profile_date ON transactions(profile_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_txn_profile_status ON transactions(profile_id, status);
CREATE INDEX IF NOT EXISTS idx_txn_from ON transactions(from_account_id);
CREATE INDEX IF NOT EXISTS idx_txn_to ON transactions(to_account_id);
CREATE INDEX IF NOT EXISTS idx_txn_card ON transactions(card_id);

-- ============================================================================
-- AUDIT LOG
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id   UUID REFERENCES profiles(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  timestamp    TIMESTAMPTZ DEFAULT now(),
  action       TEXT NOT NULL,
  entity_type  TEXT,
  entity_id    TEXT,
  before_data  JSONB,
  after_data   JSONB,
  notes        TEXT
);
CREATE INDEX IF NOT EXISTS idx_audit_profile ON audit_log(profile_id, timestamp DESC);

-- ============================================================================
-- STATEMENT UPLOADS (Card reconciliation)
-- ============================================================================
CREATE TABLE IF NOT EXISTS statement_uploads (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  card_id             UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  cycle_start         DATE NOT NULL,
  cycle_end           DATE NOT NULL,
  statement_balance   NUMERIC(15,2),
  app_balance         NUMERIC(15,2),
  variance            NUMERIC(15,2),
  notes               TEXT,
  uploaded_at         TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_stmt_card_cycle ON statement_uploads(card_id, cycle_start);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- Ensures user X cannot see/edit user Y's data, even if they bypass the app.
-- ============================================================================

ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcategories     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_flags         ENABLE ROW LEVEL SECURITY;
ALTER TABLE people            ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards             ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans             ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_events       ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurance         ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring         ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log         ENABLE ROW LEVEL SECURITY;
ALTER TABLE statement_uploads ENABLE ROW LEVEL SECURITY;

-- Profiles policy: users can only see/edit their own profiles
DROP POLICY IF EXISTS "profiles_owner" ON profiles;
CREATE POLICY "profiles_owner" ON profiles
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Generic policy generator for profile-scoped tables
DO $$
DECLARE
  t TEXT;
  table_list TEXT[] := ARRAY[
    'settings','categories','subcategories','tax_flags','people',
    'accounts','cards','loans','loan_events','insurance','investments',
    'recurring','transactions','audit_log','statement_uploads'
  ];
BEGIN
  FOREACH t IN ARRAY table_list LOOP
    EXECUTE format('DROP POLICY IF EXISTS "%I_profile_scoped" ON %I', t, t);
    EXECUTE format(
      'CREATE POLICY "%I_profile_scoped" ON %I FOR ALL
       USING (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))
       WITH CHECK (profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid()))',
      t, t
    );
  END LOOP;
END $$;

-- ============================================================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  t TEXT;
  table_list TEXT[] := ARRAY[
    'profiles','settings','categories','subcategories','tax_flags','people',
    'accounts','cards','loans','insurance','investments','recurring',
    'transactions','statement_uploads'
  ];
BEGIN
  FOREACH t IN ARRAY table_list LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%I_touch ON %I', t, t);
    EXECUTE format(
      'CREATE TRIGGER trg_%I_touch BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION touch_updated_at()',
      t, t
    );
  END LOOP;
END $$;

-- ============================================================================
-- ENABLE REALTIME ON ALL TABLES
-- Required for postgres_changes events to fire (multi-device sync).
-- ============================================================================
DO $$
DECLARE
  t TEXT;
  table_list TEXT[] := ARRAY[
    'profiles','settings','categories','subcategories','tax_flags','people',
    'accounts','cards','loans','loan_events','insurance','investments',
    'recurring','transactions','statement_uploads','audit_log'
  ];
BEGIN
  FOREACH t IN ARRAY table_list LOOP
    BEGIN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I', t);
    EXCEPTION WHEN OTHERS THEN
      NULL; -- already in publication or table doesn't exist
    END;
  END LOOP;
END $$;

-- ============================================================================
-- DONE.
-- Verify: Run "SELECT tablename FROM pg_tables WHERE schemaname='public'" to see all tables.
-- You should see ~16 tables.
-- Also verify realtime: in Supabase dashboard → Database → Replication →
--   all tables should show "Realtime ON".
-- ============================================================================
