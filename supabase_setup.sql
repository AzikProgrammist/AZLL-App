-- AZ Language Learning — Supabase SQL (v2, xavfsiz)
-- Supabase → SQL Editor → paste → Run. Qayta ishga tushirsa ham xato bermaydi.

-- 1) Jadvallar
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT,
  email       TEXT,
  plan        TEXT DEFAULT 'free',
  streak      INTEGER DEFAULT 0,
  daily_goal  INTEGER DEFAULT 10,
  daily_done  INTEGER DEFAULT 0,
  last_active TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_words (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  lang       TEXT NOT NULL,
  words      JSONB DEFAULT '[]',
  stats      JSONB DEFAULT '{"correct":0,"wrong":0}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lang)
);

CREATE TABLE IF NOT EXISTS config (
  key        TEXT PRIMARY KEY,
  value      JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2) Admin tekshiruvi (RLS ichida rekursiya bo'lmasligi uchun alohida funksiya)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
      AND email = 'azimbekusmonov0919@gmail.com'
      AND email_confirmed_at IS NOT NULL
  );
$$;

-- 3) RLS
ALTER TABLE profiles   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE config     ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users see own profile"    ON profiles;
DROP POLICY IF EXISTS "Users update own profile" ON profiles;
DROP POLICY IF EXISTS "Admin sees all profiles"  ON profiles;
DROP POLICY IF EXISTS "profiles_select"          ON profiles;
DROP POLICY IF EXISTS "profiles_insert"          ON profiles;
DROP POLICY IF EXISTS "profiles_update"          ON profiles;
DROP POLICY IF EXISTS "Users manage own words"   ON user_words;
DROP POLICY IF EXISTS "words_all"                ON user_words;
DROP POLICY IF EXISTS "Anyone can read config"   ON config;
DROP POLICY IF EXISTS "Only admin writes config" ON config;
DROP POLICY IF EXISTS "config_select"            ON config;
DROP POLICY IF EXISTS "config_write"             ON config;

CREATE POLICY "profiles_select" ON profiles FOR SELECT
  USING (auth.uid() = id OR public.is_admin());
CREATE POLICY "profiles_insert" ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE
  USING (auth.uid() = id OR public.is_admin())
  WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY "words_all" ON user_words FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "config_select" ON config FOR SELECT USING (true);
CREATE POLICY "config_write"  ON config FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 4) Foydalanuvchi o'ziga Premium bera olmasligi uchun himoya
CREATE OR REPLACE FUNCTION public.protect_plan()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF TG_OP = 'INSERT' THEN
      NEW.plan := 'free';
    ELSE
      NEW.plan := OLD.plan;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_plan_trg ON profiles;
CREATE TRIGGER protect_plan_trg
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_plan();

-- 5) Yangi foydalanuvchi ro'yxatdan o'tganda profil avtomatik yaratiladi
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, plan, streak, daily_goal, daily_done, last_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email,'@',1)),
    NEW.email, 'free', 0, 10, 0, ''
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
