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
-- ========================
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

CREATE TABLE IF NOT EXISTS otp_verification (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  otp_code VARCHAR(10) NOT NULL,
  username VARCHAR(100) NOT NULL,
  phone_number VARCHAR(20) NULL,
  password_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  verified TINYINT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- category (lookup)
-- ========================
CREATE TABLE IF NOT EXISTS category (
    category_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NULL, -- (เผื่อเป็นหมวดหมู่ส่วนตัว)
    category_name VARCHAR(100) NOT NULL,
    category_type ENUM('income', 'expense') NOT NULL,
    
    -- ⭐️ นี่คือฟิลด์ที่โค้ด Node.js ของคุณต้องการ ⭐️
    color_hex VARCHAR(7) NOT NULL DEFAULT '#CCCCCC', 
    
    -- (ฟิลด์อื่นๆ เช่น ไอคอน)
    icon_name VARCHAR(50) NULL,
    
    UNIQUE(user_id, category_name, category_type), -- ป้องกันชื่อหมวดหมู่ซ้ำกันในประเภทเดียวกัน
    CONSTRAINT fk_cat_user FOREIGN KEY (user_id)
      REFERENCES users(user_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_cat_user_type ON category(user_id, category_type);

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
  occupation_name VARCHAR(100) NOT NULL UNIQUE
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
  code VARCHAR(20) NOT NULL UNIQUE
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
-- debt (1:N with profile)
-- ========================
CREATE TABLE IF NOT EXISTS debt (
  debt_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  profile_id BIGINT UNSIGNED NOT NULL COMMENT 'FK ชี้ไปที่ profile ของผู้ใช้',

  debt_type VARCHAR(100) NOT NULL COMMENT 'ประเภทหนี้ (เช่น บัตรเครดิต, สินเชื่อรถ, สินเชื่อบ้าน, กยศ.)',
  debt_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00 COMMENT 'ยอดหนี้คงเหลือ',
  
  -- === คอลัมน์สำคัญสำหรับ Logic ===
  debt_interest_rate DECIMAL(5, 2) NOT NULL DEFAULT 0.00 COMMENT 'อัตราดอกเบี้ยต่อปี (เช่น 18.50 สำหรับ 18.5%)',
  debt_monthly_payment DECIMAL(12, 2) NOT NULL DEFAULT 0.00 COMMENT 'ยอดผ่อนชำระต่อเดือน',
  -- ===============================
  
  debt_duration_months INT UNSIGNED NULL COMMENT 'ระยะเวลาผ่อนที่เหลือ (เดือน)',

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- === Constraints ===
  CONSTRAINT fk_debt_profile FOREIGN KEY (profile_id)
    REFERENCES profile(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    
  -- ตรวจสอบว่าค่าเป็นบวกเสมอ
  CONSTRAINT chk_debt_amount_nonneg CHECK (debt_amount >= 0),
  CONSTRAINT chk_debt_rate_nonneg CHECK (debt_interest_rate >= 0),
  CONSTRAINT chk_debt_payment_nonneg CHECK (debt_monthly_payment >= 0)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- สร้าง Index เพื่อการค้นหาที่รวดเร็ว
CREATE INDEX ix_debt_profile ON debt(profile_id);

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
  
  -- ▼▼▼ ส่วนที่เปลี่ยนแปลง ▼▼▼ --
  
  -- 1. เปลี่ยนชื่อจาก monthly_contribution
  contribution_amount DECIMAL(14,2) NOT NULL DEFAULT 0, 
  
  -- 2. ลบ duration_months ทิ้งไป
  
  frequency ENUM('monthly','weekly','daily','one-time') DEFAULT 'monthly',
  
  -- 3. เพิ่มคอลัมน์นี้สำหรับระบบหักเงินอัตโนมัติ
  next_deduction_date DATE NULL, 
  
  -- ▲▲▲ สิ้นสุดส่วนที่เปลี่ยนแปลง ▲▲▲ --

  status ENUM('active','paused','completed','cancelled') NOT NULL DEFAULT 'active',
  start_date DATE NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT chk_goal_target_pos CHECK (target_amount > 0),
  
  -- อย่าลืมเปลี่ยนชื่อ Constraint นี้ด้วย
  CONSTRAINT chk_goal_contribution_nonneg CHECK (contribution_amount >= 0), 

  CONSTRAINT fk_goal_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_goal_wallet FOREIGN KEY (wallet_id) REFERENCES wallet(wallet_id)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT uq_goal_user_name UNIQUE (user_id, goal_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_goal_user ON saving_goals(user_id);
CREATE INDEX ix_goal_wallet ON saving_goals(wallet_id);

-- เพิ่ม Index นี้ด้วย จะช่วยให้ Cron Job ทำงานเร็วขึ้นมาก
CREATE INDEX ix_goal_next_deduction ON saving_goals(status, next_deduction_date);
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
CREATE TABLE IF NOT EXISTS stocks (
  stock_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  symbol VARCHAR(32) NOT NULL,
  long_name VARCHAR(255) NULL,
  current_price DECIMAL(18,6) NULL,
  market_cap DECIMAL(20,2) NULL,
  sector VARCHAR(100) NULL,
  industry VARCHAR(100) NULL,
  last_updated TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_stock_symbol (symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS stocksTH (
  stock_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  symbol VARCHAR(32) NOT NULL,
  long_name VARCHAR(255) NULL,
  current_price DECIMAL(18,6) NULL,
  market_cap DECIMAL(20,2) NULL,
  sector VARCHAR(100) NULL,
  industry VARCHAR(100) NULL,
  last_updated TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_stock_symbol (symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS funds (
  fund_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  symbol VARCHAR(32) NOT NULL,
  long_name VARCHAR(255) NULL,
  current_price DECIMAL(18,6) NULL,
  category VARCHAR(100) NULL,
  total_assets DECIMAL(20,2) NULL,
  nav_price DECIMAL(18,6) NULL,
  ytd_return DECIMAL(8,6) NULL,
  last_updated TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_fund_symbol (symbol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  is_read TINYINT NOT NULL DEFAULT 0,
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
  user_id BIGINT UNSIGNED NULL, -- 👈 [THE FIX] ทำให้คอลัมน์นี้สามารถเป็น NULL ได้
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
    ON DELETE SET NULL ON UPDATE CASCADE -- 👈 เมื่อ user ถูกลบ ให้ตั้งค่าใน log เป็น NULL
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
  question_type ENUM('single_choice','multi_choice') NOT NULL,
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

-- คำถามที่ 1: วัดทัศนคติต่อความเสี่ยง (Risk Tolerance)
INSERT INTO survey_question (question_text, question_type, options) VALUES
('สมมติว่าคุณลงทุน 100,000 บาท หนึ่งเดือนต่อมา ตลาดผันผวนหนัก ทำให้เงินของคุณเหลือ 80,000 บาท (ขาดทุน 20,000 บาท) คุณจะทำอย่างไร?', 'single_choice',
'[{"value": "A", "label": "ขายทิ้งทันทีทั้งหมด เพราะรับไม่ได้ที่จะขาดทุนไปมากกว่านี้"},
  {"value": "B", "label": "ถือไว้ก่อน และติดตามสถานการณ์อย่างใกล้ชิด"},
  {"value": "C", "label": "ซื้อเพิ่ม เพราะคิดว่าเป็นโอกาสที่ดีในการซื้อของถูก"},
  {"value": "SKIP", "label": "ไม่แน่ใจ / ขอข้ามข้อนี้"}]');

-- คำถามที่ 2: วัดวินัยทางการเงิน (Spending Behavior)
INSERT INTO survey_question (question_text, question_type, options) VALUES
('ข้อใดอธิบายพฤติกรรมการใช้เงินของคุณได้ดีที่สุด?', 'single_choice',
'[{"value": "A", "label": "ฉันวางแผนงบประมาณ (Budget) อย่างเคร่งครัด และใช้เงินตามแผนเสมอ"},
  {"value": "B", "label": "พยายามจะออม แต่บางครั้งก็ใช้จ่ายตามอารมณ์บ้าง"},
  {"value": "C", "label": "มักจะใช้เงินก่อน แล้วค่อยออมส่วนที่เหลือ (ถ้ามี)"},
  {"value": "SKIP", "label": "ไม่แน่ใจ / ขอข้ามข้อนี้"}]');

-- คำถามที่ 3: วัดความมั่นคงทางการเงิน (Financial Stability)
INSERT INTO survey_question (question_text, question_type, options) VALUES
('คุณมี ''เงินสำรองฉุกเฉิน'' (เงินสดที่ครอบคลุมค่าใช้จ่าย 3-6 เดือน) แล้วหรือยัง?', 'single_choice',
'[{"value": "A", "label": "มีครบถ้วนแล้ว"},
  {"value": "B", "label": "มีบ้าง แต่ยังไม่ครบ 3-6 เดือน"},
  {"value": "C", "label": "ยังไม่มีเลย"},
  {"value": "SKIP", "label": "ไม่แน่ใจ / ขอข้ามข้อนี้"}]');

-- คำถามที่ 4: วัดความรู้ด้านการลงทุน (Financial Knowledge)
INSERT INTO survey_question (question_text, question_type, options) VALUES
('คุณมีความเข้าใจหรือคุ้นเคยกับผลิตภัณฑ์การเงินใดบ้าง? (เลือกได้หลายข้อ)', 'multi_choice',
'[{"value": "SAVINGS", "label": "เงินฝากออมทรัพย์ / ฝากประจำ"},
  {"value": "MUTUAL_FUND", "label": "กองทุนรวม (เช่น กองทุนตราสารหนี้, กองทุนหุ้น)"},
  {"value": "STOCK", "label": "หุ้นรายตัว"},
  {"value": "BOND", "label": "ตราสารหนี้ (พันธบัตร)"},
  {"value": "CRYPTO", "label": "สินทรัพย์ดิจิทัล (Cryptocurrency)"},
  {"value": "NONE", "label": "ไม่คุ้นเคยกับการลงทุนใดๆ เลย"}]');

-- คำถามที่ 5: วัดเป้าหมายเชิงคุณภาพ (Qualitative Goal)
INSERT INTO survey_question (question_text, question_type, options) VALUES
('อะไรคือเป้าหมายหลัก ''ที่แท้จริง'' ของการลงทุนนี้?', 'single_choice',
'[{"value": "CAPITAL_PRESERVATION", "label": "เพื่อรักษาเงินต้นให้ปลอดภัย (ชนะเงินเฟ้อ)"},
  {"value": "STABLE_GROWTH", "label": "เพื่อให้เงินงอกเงยอย่างมั่นคง (วางแผนเกษียณ, ซื้อบ้าน)"},
  {"value": "MAX_RETURN", "label": "เพื่อสร้างผลตอบแทนสูงสุด แม้จะต้องเสี่ยงสูง (สร้างความมั่งคั่ง)"},
  {"value": "SKIP", "label": "ไม่แน่ใจ / ขอข้ามข้อนี้"}]');

-- คำถามที่ 6: วัดความสนใจ (Personal Interest)
INSERT INTO survey_question (question_text, question_type, options) VALUES
('คุณสนใจลงทุนในอุตสาหกรรมใดเป็นพิเศษ? (เลือกได้หลายข้อ)', 'multi_choice',
'[{"value": "TECH", "label": "เทคโนโลยี (Tech) / นวัตกรรม"},
  {"value": "HEALTHCARE", "label": "สุขภาพ (Healthcare)"},
  {"value": "ENERGY_UTILITIES", "label": "พลังงาน / สาธารณูปโภค (Energy / Utilities)"},
  {"value": "CONSUMER", "label": "สินค้าอุปโภคบริโภค (Consumer Goods)"},
  {"value": "FINANCE", "label": "การเงิน / ธนาคาร (Finance / Banking)"},
  {"value": "ANY", "label": "ไม่มีอะไรเป็นพิเศษ / ให้ระบบแนะนำได้เลย"}]');

-- ========================
-- investment_recommendation (Polymorphic Version)
-- ========================
CREATE TABLE IF NOT EXISTS investment_recommendation (
  recommendation_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  goal_id BIGINT UNSIGNED NOT NULL COMMENT 'FK ชี้ไปที่ saving_goals',
  
  -- === ส่วนที่รองรับ 3 ตาราง (stocks, stocksTH, funds) ===
  investment_type ENUM('stock', 'stockTH', 'fund') NOT NULL COMMENT 'บอกว่าสินทรัพย์นี้มาจากตารางไหน',
  investment_ref_id BIGINT UNSIGNED NOT NULL COMMENT 'ID ที่อ้างอิง (เช่น stock_id หรือ fund_id)',
  -- ===================================================
  
  recommended_allocation_percent DECIMAL(5,2) NOT NULL CHECK (recommended_allocation_percent >= 0 AND recommended_allocation_percent <= 100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Foreign Key ไปที่ goal
  CONSTRAINT fk_ir_goal FOREIGN KEY (goal_id) REFERENCES saving_goals(goal_id)
    ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- สร้าง Index เพื่อการค้นหาที่รวดเร็ว
CREATE INDEX ix_ir_goal ON investment_recommendation(goal_id);
CREATE INDEX ix_ir_investment_poly ON investment_recommendation(investment_type, investment_ref_id);
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

CREATE TABLE IF NOT EXISTS token_blocklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token_jti VARCHAR(255) NOT NULL UNIQUE,  -- 'jti' (JWT ID) คือ ID ของ Token
    user_id INT NOT NULL,
    expires_at DATETIME NOT NULL,          -- วันหมดอายุของ Token
    blocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (user_id),
    INDEX (expires_at)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================
-- Final housekeeping: 권장 indices already created above
-- ========================

-- END OF SCRIPT