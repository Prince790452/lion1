/*
  # Authentication and Study Data Schema

  ## Overview
  Sets up authentication-ready database with user profiles and study planning data.

  ## New Tables
  
  ### `user_profiles`
  - `id` (uuid, primary key) - References auth.users
  - `email` (text) - User's email address
  - `full_name` (text) - User's display name
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last profile update timestamp

  ### `study_plans`
  - `id` (uuid, primary key) - Unique plan identifier
  - `user_id` (uuid, foreign key) - References user_profiles.id
  - `title` (text) - Study plan title
  - `description` (text) - Plan description
  - `start_date` (date) - Plan start date
  - `end_date` (date) - Plan end date
  - `status` (text) - Plan status (active, completed, archived)
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `study_tasks`
  - `id` (uuid, primary key) - Unique task identifier
  - `plan_id` (uuid, foreign key) - References study_plans.id
  - `user_id` (uuid, foreign key) - References user_profiles.id
  - `title` (text) - Task title
  - `description` (text) - Task description
  - `due_date` (date) - Task deadline
  - `priority` (text) - Priority level (high, medium, low)
  - `status` (text) - Task status (todo, in_progress, completed)
  - `completed_at` (timestamptz) - Completion timestamp
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Security
  1. Enable RLS on all tables
  2. Users can only access their own data
  3. Policies for SELECT, INSERT, UPDATE, DELETE operations
  
  ## Notes
  - All tables use UUID primary keys
  - Timestamps use timestamptz for timezone support
  - Foreign keys enforce referential integrity
  - Cascading deletes protect data consistency
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Create study_plans table
CREATE TABLE IF NOT EXISTS study_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text DEFAULT '',
  start_date date,
  end_date date,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE study_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own study plans"
  ON study_plans FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study plans"
  ON study_plans FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study plans"
  ON study_plans FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own study plans"
  ON study_plans FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create study_tasks table
CREATE TABLE IF NOT EXISTS study_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid REFERENCES study_plans(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text DEFAULT '',
  due_date date,
  priority text DEFAULT 'medium',
  status text DEFAULT 'todo',
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE study_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own study tasks"
  ON study_tasks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study tasks"
  ON study_tasks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study tasks"
  ON study_tasks FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own study tasks"
  ON study_tasks FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_study_plans_user_id ON study_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_study_tasks_user_id ON study_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_study_tasks_plan_id ON study_tasks(plan_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_profiles_updated_at'
  ) THEN
    CREATE TRIGGER update_user_profiles_updated_at
      BEFORE UPDATE ON user_profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_study_plans_updated_at'
  ) THEN
    CREATE TRIGGER update_study_plans_updated_at
      BEFORE UPDATE ON study_plans
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'update_study_tasks_updated_at'
  ) THEN
    CREATE TRIGGER update_study_tasks_updated_at
      BEFORE UPDATE ON study_tasks
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;