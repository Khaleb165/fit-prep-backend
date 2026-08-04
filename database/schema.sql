CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT users_username_not_blank CHECK (length(trim(username)) > 0),
  CONSTRAINT users_email_not_blank CHECK (length(trim(email)) > 0),
  CONSTRAINT users_password_hash_not_blank CHECK (length(trim(password_hash)) > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS users_username_lower_idx
  ON users (lower(username));

CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_idx
  ON users (lower(email));

CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  gym_session TEXT NOT NULL,
  packing_time TEXT NOT NULL,
  reminder TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT plans_title_not_blank CHECK (length(trim(title)) > 0),
  CONSTRAINT plans_gym_session_valid CHECK (
    gym_session IN ('morning', 'afternoon', 'evening')
  ),
  CONSTRAINT plans_packing_time_valid CHECK (
    packing_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
  ),
  CONSTRAINT plans_reminder_valid CHECK (
    reminder IN ('on_time', 'one_hour_before')
  )
);

CREATE INDEX IF NOT EXISTS plans_user_id_created_at_idx
  ON plans (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS plan_items (
  plan_id TEXT NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  id TEXT NOT NULL,
  title TEXT NOT NULL,
  is_checked BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (plan_id, id),
  CONSTRAINT plan_items_title_not_blank CHECK (length(trim(title)) > 0)
);

CREATE INDEX IF NOT EXISTS plan_items_plan_id_sort_order_idx
  ON plan_items (plan_id, sort_order);
