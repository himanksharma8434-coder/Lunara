-- ─────────────────────────────────────────────────────────
-- Lunara: Row Level Security (RLS) Policies (SAFE CAST VERSION)
-- ─────────────────────────────────────────────────────────
-- Run this script in your Supabase SQL Editor.
-- This version uses ::text casting to ensure that UUID mismatches
-- don't silently block the queries!
-- ─────────────────────────────────────────────────────────

-- 1. Ensure RLS is enabled on the necessary tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────
-- USERS TABLE POLICIES
-- ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" 
ON public.users FOR SELECT 
USING (auth.uid()::text = uid::text);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" 
ON public.users FOR INSERT 
WITH CHECK (auth.uid()::text = uid::text);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" 
ON public.users FOR UPDATE 
USING (auth.uid()::text = uid::text) 
WITH CHECK (auth.uid()::text = uid::text);

-- ─────────────────────────────────────────────────────────
-- CYCLES TABLE POLICIES
-- ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view own cycles" ON public.cycles;
CREATE POLICY "Users can view own cycles" 
ON public.cycles FOR SELECT 
USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert own cycles" ON public.cycles;
CREATE POLICY "Users can insert own cycles" 
ON public.cycles FOR INSERT 
WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update own cycles" ON public.cycles;
CREATE POLICY "Users can update own cycles" 
ON public.cycles FOR UPDATE 
USING (auth.uid()::text = user_id::text) 
WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can delete own cycles" ON public.cycles;
CREATE POLICY "Users can delete own cycles" 
ON public.cycles FOR DELETE 
USING (auth.uid()::text = user_id::text);

-- ─────────────────────────────────────────────────────────
-- ASSESSMENTS TABLE POLICIES
-- ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can view own assessments" ON public.assessments;
CREATE POLICY "Users can view own assessments" 
ON public.assessments FOR SELECT 
USING (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can insert own assessments" ON public.assessments;
CREATE POLICY "Users can insert own assessments" 
ON public.assessments FOR INSERT 
WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can update own assessments" ON public.assessments;
CREATE POLICY "Users can update own assessments" 
ON public.assessments FOR UPDATE 
USING (auth.uid()::text = user_id::text) 
WITH CHECK (auth.uid()::text = user_id::text);

DROP POLICY IF EXISTS "Users can delete own assessments" ON public.assessments;
CREATE POLICY "Users can delete own assessments" 
ON public.assessments FOR DELETE 
USING (auth.uid()::text = user_id::text);
