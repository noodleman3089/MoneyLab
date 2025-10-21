-- MoneyLab Schema v2 (adapted to ER-Diagram)
-- MySQL 8+ recommended
SET NAMES utf8mb4;
SET time_zone = '+07:00';

-- ลบ schema เดิมถ้ามีอยู่ (สำรองก่อนรันจริง)
DROP SCHEMA IF EXISTS moneylab;

CREATE SCHEMA moneylab
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

USE moneylab;

-- ========================
-- users
 ========================
CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  role ENUM('user','admin') NOT NULL DEFAULT 'user',
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NULL UNIQUE,
  phone_number VARCHAR(20) NULL,
  password_hash VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;--

-- ========================
-- category (lookup)
-- ========================
CREATE TABLE IF NOT EXISTS category (
  category_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  category_name VARCHAR(100) NOT NULL,
  category_type ENUM('income','expense','transfer') NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_category_name_type (category_name, category_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- wallet
-- ========================
CREATE TABLE IF NOT EXISTS wallet (
  wallet_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  wallet_name VARCHAR(120) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'THB',
  balance DECIMAL(16,2) NOT NULL DEFAULT 0.00,
  last_reset_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_wallet_user FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_wallet_user ON wallet(user_id);

-- ========================
-- transactions
-- (ชื่อ: transactions ให้สอดคล้องกับ ERD)
-- ========================
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,

  user_id BIGINT UNSIGNED NOT NULL,
  wallet_id BIGINT UNSIGNED NULL,     -- ถ้ามีหลายบัญชี/กระเป๋า
  category_id SMALLINT UNSIGNED NULL,

  type ENUM('income','expense','transfer') NOT NULL,
  amount DECIMAL(14,2) NOT NULL CHECK (amount >= 0),
  fee DECIMAL(14,2) NOT NULL DEFAULT 0.00 CHECK (fee >= 0),
  net_amount DECIMAL(14,2) AS (amount - fee) STORED, -- net = amount - fee (ปรับตามนโยบาย)
  transaction_date DATETIME NOT NULL,
  sender_name VARCHAR(255) NULL,
  receiver_name VARCHAR(255) NULL,
  reference_id VARCHAR(255) NULL,
  payment_source VARCHAR(100) NULL,
  data_source ENUM('manual','api','ocr','ml') DEFAULT 'manual',
  confidence DECIMAL(5,4) NULL, -- 0.9500
  receipt_image_url VARCHAR(1000) NULL,

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_tx_user FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_tx_wallet FOREIGN KEY (wallet_id)
    REFERENCES wallet(wallet_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT fk_tx_category FOREIGN KEY (category_id)
    REFERENCES category(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_tx_user ON transactions(user_id);
CREATE INDEX ix_tx_wallet ON transactions(wallet_id);
CREATE INDEX ix_tx_category ON transactions(category_id);
CREATE INDEX ix_tx_date ON transactions(transaction_date);
CREATE INDEX ix_tx_type ON transactions(type);
CREATE INDEX ix_tx_user_date ON transactions(user_id, transaction_date);

-- ========================
-- daily_budget
-- ========================
CREATE TABLE IF NOT EXISTS daily_budget (
  budget_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  budget_date DATE NOT NULL,
  target_spend DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT chk_target_spend_nonneg CHECK (target_spend >= 0),
  UNIQUE KEY uq_daily_budget_user_date (user_id, budget_date),

  CONSTRAINT fk_daily_budget_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_daily_budget_user ON daily_budget(user_id);
CREATE INDEX ix_daily_budget_date ON daily_budget(budget_date);

-- ========================
-- budget (bigger period budgets) - ตาม ERD ถ้ามี
-- ========================
CREATE TABLE IF NOT EXISTS budget (
  budget_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NULL, -- ถ้ามีระบบแผน (placeholder)
  budget_date DATE NULL,
  target_amount DECIMAL(14,2) DEFAULT 0,
  total_expense DECIMAL(14,2) DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_budget_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- occupation (lookup)
-- ========================
CREATE TABLE IF NOT EXISTS occupation (
  occupation_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  occupation_name VARCHAR(100) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- seed sample
INSERT INTO occupation (occupation_name) VALUES
('นักศึกษา/นักเรียน'),
('แม่ค้าขายของ'),
('พนักงานพาร์ทไทม์'),
('พนักงานประจำ'),
('อาชีพอื่นๆ');

-- ========================
-- income_period (lookup)
-- ========================
CREATE TABLE IF NOT EXISTS income_period (
  period_id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name_th VARCHAR(50) NOT NULL UNIQUE,
  code VARCHAR(20) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO income_period (name_th, code) VALUES
('รายวัน','daily'),
('รายสัปดาห์','weekly'),
('รายเดือน','monthly'),
('รายปี','yearly');

-- ========================
-- profile (1:1 กับ users)
-- ========================
CREATE TABLE IF NOT EXISTS profile (
  profile_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  occupation_id TINYINT UNSIGNED NULL,
  occupation_other VARCHAR(255) NULL,
  main_income_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  main_income_period_id TINYINT UNSIGNED NULL,
  side_income_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  side_income_period_id TINYINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT chk_main_income_nonneg CHECK (main_income_amount >= 0),
  CONSTRAINT chk_side_income_nonneg CHECK (side_income_amount >= 0),

  CONSTRAINT fk_profile_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_profile_occupation FOREIGN KEY (occupation_id) REFERENCES occupation(occupation_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT fk_profile_main_period FOREIGN KEY (main_income_period_id) REFERENCES income_period(period_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT fk_profile_side_period FOREIGN KEY (side_income_period_id) REFERENCES income_period(period_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_profile_occ ON profile(occupation_id);
CREATE INDEX ix_profile_main_period ON profile(main_income_period_id);
CREATE INDEX ix_profile_side_period ON profile(side_income_period_id);

-- ========================
-- saving_goals
-- ========================
CREATE TABLE IF NOT EXISTS saving_goals (
  goal_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  wallet_id BIGINT UNSIGNED NULL,
  goal_name VARCHAR(150) NOT NULL,
  target_amount DECIMAL(14,2) NOT NULL,
  current_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  monthly_contribution DECIMAL(14,2) NOT NULL DEFAULT 0,
  duration_months INT NULL,
  frequency ENUM('monthly','weekly','daily','one-time') DEFAULT 'monthly',
  status ENUM('active','paused','completed','cancelled') NOT NULL DEFAULT 'active',
  start_date DATE NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT chk_goal_target_pos CHECK (target_amount > 0),
  CONSTRAINT chk_goal_monthly_nonneg CHECK (monthly_contribution >= 0),

  CONSTRAINT fk_goal_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_goal_wallet FOREIGN KEY (wallet_id) REFERENCES wallet(wallet_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT uq_goal_user_name UNIQUE (user_id, goal_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_goal_user ON saving_goals(user_id);
CREATE INDEX ix_goal_wallet ON saving_goals(wallet_id);

-- ========================
-- saving_transactions (contributions / withdrawals to goals)
-- ========================
CREATE TABLE IF NOT EXISTS saving_transactions (
  saving_transaction_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  goal_id BIGINT UNSIGNED NOT NULL,
  wallet_id BIGINT UNSIGNED NULL,
  amount DECIMAL(14,2) NOT NULL CHECK (amount >= 0),
  transaction_date DATETIME NOT NULL,
  status ENUM('pending','completed','failed') NOT NULL DEFAULT 'completed',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_saving_tx_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_saving_tx_goal FOREIGN KEY (goal_id) REFERENCES saving_goals(goal_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_saving_tx_wallet FOREIGN KEY (wallet_id) REFERENCES wallet(wallet_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_saving_tx_user ON saving_transactions(user_id);
CREATE INDEX ix_saving_tx_goal ON saving_transactions(goal_id);
CREATE INDEX ix_saving_tx_wallet ON saving_transactions(wallet_id);

-- ========================
-- investment
-- ========================
CREATE TABLE IF NOT EXISTS investment (
  investment_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  stock_symbol VARCHAR(32) NOT NULL,
  stock_name VARCHAR(255) NULL,
  current_price DECIMAL(18,6) NULL,
  market_cap DECIMAL(20,2) NULL,
  sector VARCHAR(100) NULL,
  risk_level ENUM('low','medium','high') DEFAULT 'medium',
  historical_return DECIMAL(6,4) NULL,
  last_updated TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_investment_symbol (stock_symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- investment_recommendation
-- link between saving_goal and investment with percent
-- ========================
CREATE TABLE IF NOT EXISTS investment_recommendation (
  recommendation_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  goal_id BIGINT UNSIGNED NOT NULL,
  investment_id BIGINT UNSIGNED NOT NULL,
  recommended_allocation_percent DECIMAL(5,2) NOT NULL CHECK (recommended_allocation_percent >= 0 AND recommended_allocation_percent <= 100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_ir_goal FOREIGN KEY (goal_id) REFERENCES saving_goals(goal_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_ir_investment FOREIGN KEY (investment_id) REFERENCES investment(investment_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_ir_goal ON investment_recommendation(goal_id);
CREATE INDEX ix_ir_investment ON investment_recommendation(investment_id);

-- ========================
-- notifications
-- ========================
CREATE TABLE IF NOT EXISTS notifications (
  notification_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  type ENUM('info','warning','success','error','reminder') NOT NULL DEFAULT 'info',
  title VARCHAR(255) NULL,
  message TEXT NULL,
  reference_type VARCHAR(100) NULL, -- e.g. 'transaction','goal','investment'
  reference_id VARCHAR(255) NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP NULL,

  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_notifications_user ON notifications(user_id);
CREATE INDEX ix_notifications_read ON notifications(is_read);

-- ========================
-- password_reset_tokens
-- ========================
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  token_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash VARBINARY(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pw_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  UNIQUE KEY uq_pw_token_hash (token_hash),
  INDEX ix_pw_user (user_id),
  INDEX ix_pw_expires (expires_at),
  INDEX ix_pw_used (used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- log (audit)
-- ========================
CREATE TABLE IF NOT EXISTS `log` (
  log_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  actor_id BIGINT UNSIGNED NULL, -- who caused action (user/admin/system)
  actor_type ENUM('user','admin','system','api') NOT NULL DEFAULT 'user',
  table_name VARCHAR(128) NULL,
  record_id VARCHAR(255) NULL,
  action VARCHAR(50) NULL,
  old_value JSON NULL,
  new_value JSON NULL,
  changed_fields JSON NULL,
  ip_address VARBINARY(16) NULL,
  user_agent VARCHAR(255) NULL,
  description TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_log_user ON `log` (user_id);
CREATE INDEX ix_log_created_at ON `log` (created_at);
CREATE INDEX ix_log_actor_type ON `log` (actor_type);

-- ========================
-- survey_question / survey_answer
-- ========================
CREATE TABLE IF NOT EXISTS survey_question (
  question_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  question_text TEXT NOT NULL,
  question_type ENUM('text','single_choice','multi_choice','number','rating') NOT NULL DEFAULT 'text',
  options JSON NULL, -- array of choice options for choice questions
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS survey_answer (
  answer_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  answer_value TEXT NULL,
  answered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sa_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sa_question FOREIGN KEY (question_id) REFERENCES survey_question(question_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_survey_user ON survey_answer(user_id);
CREATE INDEX ix_survey_question ON survey_answer(question_id);

-- ========================
-- Optional: seed sample category (as in original)
-- ========================
INSERT INTO category (category_name, category_type) VALUES
('รายรับประจำ',  'income'),
('รายรับเสริม',   'income'),
('รายได้จากการลงทุน',  'income'),
('เงินสนับสนุน',   'income'),
('รายรับเบ็ดเตล็ด',  'income'),
('ที่อยู่อาศัย/สาธารณูปโภค', 'expense'),
('อาหาร/เครื่องดื่ม',    'expense'),
('การเดินทาง',          'expense'),
('สุขภาพ/การดูแลตัวเอง', 'expense'),
('ไลฟ์สไตล์/บันเทิง',    'expense'),
('การศึกษา/พัฒนาตนเอง','expense'),
('ให้เงินครอบครัว',      'expense'),
('การเงิน',              'expense');

-- ========================
-- Final housekeeping: 권장 indices already created above
-- ========================

-- END OF SCRIPT
