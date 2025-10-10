
-- MoneyLab Schema v2 (MySQL 8+)
-- Consistent names, sensible defaults, and FK integrity.

SET NAMES utf8mb4;
SET time_zone = '+07:00';

-- ลบ schema เดิมถ้ามีอยู่
DROP SCHEMA IF EXISTS moneylab;

-- สร้าง schema ใหม่
CREATE SCHEMA moneylab DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- เลือกใช้งาน schema
USE moneylab;

-- Users
CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  role ENUM('user','admin') NOT NULL DEFAULT 'user',
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NULL UNIQUE,
  phone_number VARCHAR(20),
  password_hash VARCHAR(255) NULL,
  last_login_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ตารางหมวดหมู่
CREATE TABLE IF NOT EXISTS category (
    category_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    category_type ENUM('income','expense','transfer') NOT NULL,
    UNIQUE KEY uq_category_name_type (category_name, category_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ตารางธุรกรรม
-- ตารางธุรกรรม (แก้ให้ตรงมาตรฐานกับ schema ทั้งหมด)
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  -- FK ให้ตรงกับ users.user_id และ category.category_id
  user_id BIGINT UNSIGNED NOT NULL,
  category_id SMALLINT UNSIGNED NULL,

  -- ประเภทธุรกรรม
  type ENUM('income','expense','transfer') NOT NULL,

  -- จำนวนเงินหลักและค่าธรรมเนียม
  amount DECIMAL(14,2) NOT NULL CHECK (amount >= 0),
  fee DECIMAL(14,2) DEFAULT 0.00 CHECK (fee >= 0),

  -- รายละเอียดเพิ่มเติม
  sender_name VARCHAR(255) NULL,
  receiver_name VARCHAR(255) NULL,
  reference_id VARCHAR(255) NULL,
  payment_source VARCHAR(100) NULL,    -- เช่น "บัญชีธนาคาร", "TrueMoney", "เงินสด"
  data_source ENUM('manual','api','ocr','ml') DEFAULT 'manual',
  confidence DECIMAL(5,2) NULL,        -- ค่าความมั่นใจจาก ML เช่น 0.95

  -- วันที่ทำรายการ
  transaction_date DATE NOT NULL,

  -- เวลาสร้างและอัปเดต
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
             ON UPDATE CURRENT_TIMESTAMP,

  -- ความสัมพันธ์กับผู้ใช้และหมวดหมู่
  CONSTRAINT fk_tx_user FOREIGN KEY (user_id)
    REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_tx_category FOREIGN KEY (category_id)
    REFERENCES category(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ดัชนี
CREATE INDEX ix_tx_user ON transactions(user_id);
CREATE INDEX ix_tx_category ON transactions(category_id);
CREATE INDEX ix_tx_date ON transactions(transaction_date);
CREATE INDEX ix_tx_type ON transactions(type);
-- composite สำหรับรายงานยอดตามผู้ใช้และช่วงเวลา
CREATE INDEX ix_tx_user_date ON transactions(user_id, transaction_date);


-- ตัวอย่าง seed category เล็กน้อย (แล้วแต่รสนิยม)
INSERT INTO category (category_name, category_type) VALUES
('รายรับประจำ',  'income'),
('รายรับเสริม',     'income'),
('รายได้จากการลงทุน',  'income'),
('เงินสนับสนุน',     'income'),
('รายรับเบ็ดเตล็ด',  'income'),
('ที่อยู่อาศัยสาธารณูปโภค',      'expense'),
('อาหารเครื่องดื่ม',      'expense'),
('การเดินทาง',      'expense'),
('สุขภาพการดูแลตัวเอง',      'expense'),
('ไลฟ์สโตล์บันเทิง',      'expense'),
('การศึกษาการพัฒนาตนเอง',      'expense'),
('ให้เงินครอบครัว',      'expense'),
('การเงิน',    'expense');

-- ตารางงบประมาณรายวัน
CREATE TABLE IF NOT EXISTS daily_budget (
    budget_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- ต้องตรงกับ users.user_id ที่เราใช้ BIGINT UNSIGNED
    user_id BIGINT UNSIGNED NOT NULL,

    -- วันที่ที่งบประมาณนี้มีผล (รายวัน)
    budget_date DATE NOT NULL,

    -- วงเงินเป้าหมายต่อวัน
    target_spend DECIMAL(12,2) NOT NULL DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_target_spend_nonneg CHECK (target_spend >= 0),

    -- ผู้ใช้ 1 คนมีงบได้ 1 แถวต่อวัน
    UNIQUE KEY uq_daily_budget_user_date (user_id, budget_date),

    CONSTRAINT fk_daily_budget_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ดัชนีเสริม เวลา query ตามผู้ใช้หรือช่วงวัน
CREATE INDEX ix_daily_budget_user ON daily_budget(user_id);
CREATE INDEX ix_daily_budget_date ON daily_budget(budget_date);


-- 1) ตารางอาชีพ (lookup)
CREATE TABLE occupation (
    occupation_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_th VARCHAR(100) NOT NULL UNIQUE,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

-- seed ค่าเริ่มต้น
INSERT INTO occupation (name_th) VALUES
('นักศึกษา/นักเรียน'),
('แม่ค้าขายของ'),
('พนักงานพาร์ทไทม์'),
('พนักงานเงินเดือน'),
('อาชีพอื่นๆ');

-- 2) ตารางรอบรายได้ (lookup)
CREATE TABLE income_period (
    period_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name_th VARCHAR(50) NOT NULL UNIQUE,     -- ชื่อที่โชว์ใน dropdown
    code VARCHAR(20) NOT NULL UNIQUE,        -- โค้ดสั้นไว้ให้โค้ดฝั่งแอปใช้
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

-- seed ค่าเริ่มต้น
INSERT INTO income_period (name_th, code) VALUES
('รายวัน',    'daily'),
('รายสัปดาห์','weekly'),
('รายเดือน',  'monthly'),
('รายปี',     'yearly');

-- ตารางโปรไฟล์ (แก้ให้ชนิด FK ตรง และ 1:1 กับ users)
CREATE TABLE IF NOT EXISTS profile (
    profile_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- ต้องตรงกับ users.user_id ที่เป็น BIGINT UNSIGNED
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,

    occupation_id TINYINT UNSIGNED NULL,
    main_income_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    main_income_period_id TINYINT UNSIGNED NULL,

    side_income_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    side_income_period_id TINYINT UNSIGNED NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_main_income_nonneg CHECK (main_income_amount >= 0),
    CONSTRAINT chk_side_income_nonneg CHECK (side_income_amount >= 0),

    CONSTRAINT fk_profile_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_profile_occupation
        FOREIGN KEY (occupation_id) REFERENCES occupation(occupation_id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_profile_main_period
        FOREIGN KEY (main_income_period_id) REFERENCES income_period(period_id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT fk_profile_side_period
        FOREIGN KEY (side_income_period_id) REFERENCES income_period(period_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ดัชนีช่วย join ให้ไม่อืดเหมือนเรือพาย
CREATE INDEX ix_profile_occ ON profile(occupation_id);
CREATE INDEX ix_profile_main_period ON profile(main_income_period_id);
CREATE INDEX ix_profile_side_period ON profile(side_income_period_id);



-- Saving goals (เวอร์ชันแก้แล้วให้ตรงมาตรฐานตารางอื่น)
CREATE TABLE IF NOT EXISTS saving_goals (
  goal_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,                 -- ให้ตรงกับ users.user_id

  goal_name VARCHAR(100) NOT NULL,
  target_amount DECIMAL(14,2) NOT NULL,
  monthly_contribution DECIMAL(14,2) NOT NULL DEFAULT 0,

  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
             ON UPDATE CURRENT_TIMESTAMP,

  -- กันค่าพิลึก
  CONSTRAINT chk_goal_target_pos CHECK (target_amount > 0),
  CONSTRAINT chk_goal_monthly_nonneg CHECK (monthly_contribution >= 0),

  -- ไม่ให้ผู้ใช้ตั้งชื่อเป้าหมายซ้ำกันเอง
  CONSTRAINT uq_goal_user_name UNIQUE (user_id, goal_name),

  CONSTRAINT fk_goal_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ดัชนีเสริม ถ้ารายงานบ่อยตามผู้ใช้
CREATE INDEX ix_goal_user ON saving_goals(user_id);


CREATE TABLE IF NOT EXISTS password_reset_tokens (
  token_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash VARBINARY(64) NOT NULL,           -- เก็บแฮช เช่น SHA-256 hex -> 64 bytes
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pw_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,

  UNIQUE KEY uq_pw_token_hash (token_hash),
  INDEX ix_pw_user (user_id),
  INDEX ix_pw_expires (expires_at),
  INDEX ix_pw_used (used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ตารางบันทึกเหตุการณ์ (log)
-- ใช้ backtick กันชื่อชนกับคำสงวนในบางระบบ
CREATE TABLE IF NOT EXISTS `log` (
    log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    -- ต้องตรงกับ users.user_id ที่เราใช้ BIGINT UNSIGNED
    user_id BIGINT UNSIGNED NOT NULL,

    -- ใครเป็นคนก่อเหตุ: ผู้ใช้ / แอดมิน / ระบบ / API
    actor_type ENUM('user','admin','system','api') NOT NULL DEFAULT 'user',

    -- ค่าเดิมและค่าใหม่ เก็บเป็น JSON จะได้ diff/ตรวจสอบง่าย
    old_value JSON NULL,
    new_value JSON NULL,

    user_agent VARCHAR(255) NULL,  -- header ที่ยิงมา เช่น เบราว์เซอร์/ไลบรารี
    ip_address VARBINARY(16) NULL, -- เก็บ IPv4/IPv6 (ใส่ให้ครบๆ เผื่ออยากตามล่า)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_log_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ดัชนีที่ควรมี
CREATE INDEX ix_log_user ON `log` (user_id);
CREATE INDEX ix_log_created_at ON `log` (created_at);
CREATE INDEX ix_log_actor_type ON `log` (actor_type);
