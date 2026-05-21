SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE DATABASE IF NOT EXISTS goresidentgo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE goresidentgo;

SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW IF EXISTS vw_dashboard;
DROP TABLE IF EXISTS movement_log;
DROP TABLE IF EXISTS parking_sessions;
DROP TABLE IF EXISTS parking_spaces;
DROP TABLE IF EXISTS vehicle_rates;
DROP TABLE IF EXISTS residents;
DROP TABLE IF EXISTS password_resets;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS system_counters;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE system_counters (
  counter_name VARCHAR(50) NOT NULL,
  counter_value INT NOT NULL DEFAULT 0,
  PRIMARY KEY (counter_name)
) ENGINE=InnoDB;

INSERT INTO system_counters(counter_name, counter_value)
VALUES ('ticket', 1000);

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(120) NULL,
  email VARCHAR(190) NOT NULL,
  pass_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'porteria', 'residente') NOT NULL,
  unit_name VARCHAR(120) NULL,
  plate VARCHAR(10) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_email (email),
  UNIQUE KEY uk_users_plate (plate),
  KEY idx_users_role (role),
  KEY idx_users_unit_name (unit_name)
) ENGINE=InnoDB;

CREATE TABLE password_resets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_password_resets_token_hash (token_hash),
  KEY idx_password_resets_user_id (user_id),
  CONSTRAINT fk_password_resets_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE residents (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NULL,
  full_name VARCHAR(120) NOT NULL,
  unit_name VARCHAR(120) NOT NULL,
  plate VARCHAR(10) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_residents_user_id (user_id),
  UNIQUE KEY uk_residents_plate (plate),
  KEY idx_residents_unit_name (unit_name),
  CONSTRAINT fk_residents_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE vehicle_rates (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  vehicle_type ENUM('Carro', 'Moto', 'Bicicleta') NOT NULL,
  hour_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
  day_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
  month_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_vehicle_rates_type (vehicle_type)
) ENGINE=InnoDB;

CREATE TABLE parking_spaces (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(10) NOT NULL,
  sector CHAR(1) NOT NULL,
  slot_number TINYINT UNSIGNED NOT NULL,
  allowed_vehicle_type ENUM('Carro', 'Moto', 'Bicicleta') NOT NULL,
  access_allowed ENUM('Residente', 'Visitante', 'Ambos') NOT NULL,
  is_occupied TINYINT(1) NOT NULL DEFAULT 0,
  current_plate VARCHAR(10) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_parking_spaces_code (code),
  UNIQUE KEY uk_parking_spaces_sector_slot (sector, slot_number),
  KEY idx_parking_spaces_is_occupied (is_occupied),
  KEY idx_parking_spaces_access_allowed (access_allowed),
  KEY idx_parking_spaces_allowed_vehicle_type (allowed_vehicle_type)
) ENGINE=InnoDB;

CREATE TABLE parking_sessions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ticket VARCHAR(20) NOT NULL,
  plate VARCHAR(10) NOT NULL,
  vehicle_type ENUM('Carro', 'Moto', 'Bicicleta') NOT NULL,
  access_type ENUM('Residente', 'Visitante') NOT NULL,
  unit_name VARCHAR(120) NULL,
  space_id BIGINT UNSIGNED NOT NULL,
  resident_id BIGINT UNSIGNED NULL,
  authorized_by_resident_id BIGINT UNSIGNED NULL,
  authorized_ok TINYINT(1) NOT NULL DEFAULT 0,
  visitor_name VARCHAR(120) NULL,
  visitor_document VARCHAR(50) NULL,
  visitor_notes TEXT NULL,
  entry_by_user_id BIGINT UNSIGNED NULL,
  exit_by_user_id BIGINT UNSIGNED NULL,
  entered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  exited_at DATETIME NULL,
  minutes_parked INT NULL,
  charged_amount DECIMAL(10,2) NULL,
  payment_status ENUM('Pendiente', 'Pagado', 'Sin pago') NOT NULL DEFAULT 'Pendiente',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_parking_sessions_ticket (ticket),
  KEY idx_parking_sessions_plate_active (plate, exited_at),
  KEY idx_parking_sessions_entered_at (entered_at),
  KEY idx_parking_sessions_space_id (space_id),
  CONSTRAINT fk_parking_sessions_space
    FOREIGN KEY (space_id) REFERENCES parking_spaces(id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_parking_sessions_resident
    FOREIGN KEY (resident_id) REFERENCES residents(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT fk_parking_sessions_authorized_by
    FOREIGN KEY (authorized_by_resident_id) REFERENCES residents(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT fk_parking_sessions_entry_user
    FOREIGN KEY (entry_by_user_id) REFERENCES users(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT fk_parking_sessions_exit_user
    FOREIGN KEY (exit_by_user_id) REFERENCES users(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE movement_log (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  session_id BIGINT UNSIGNED NOT NULL,
  movement_ts DATETIME NOT NULL,
  event_type ENUM('Entrada', 'Salida') NOT NULL,
  status ENUM('Pendiente', 'Pagado', 'Sin pago') NOT NULL,
  plate VARCHAR(10) NOT NULL,
  ticket VARCHAR(20) NOT NULL,
  access_type ENUM('Residente', 'Visitante') NOT NULL,
  unit_name VARCHAR(120) NULL,
  vehicle_type ENUM('Carro', 'Moto', 'Bicicleta') NOT NULL,
  space_code VARCHAR(10) NOT NULL,
  sector CHAR(1) NOT NULL,
  spot_rule ENUM('Residente', 'Visitante', 'Ambos') NOT NULL,
  visitor_name VARCHAR(120) NULL,
  visitor_document VARCHAR(50) NULL,
  authorized_by VARCHAR(120) NULL,
  notes TEXT NULL,
  charged_amount DECIMAL(10,2) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_movement_log_ts (movement_ts),
  KEY idx_movement_log_plate (plate),
  KEY idx_movement_log_ticket (ticket),
  KEY idx_movement_log_session_id (session_id),
  CONSTRAINT fk_movement_log_session
    FOREIGN KEY (session_id) REFERENCES parking_sessions(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

DROP TRIGGER IF EXISTS trg_users_bi_validate $$
CREATE TRIGGER trg_users_bi_validate
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
  SET NEW.email = LOWER(TRIM(NEW.email));

  IF NEW.full_name IS NOT NULL AND TRIM(NEW.full_name) = '' THEN
    SET NEW.full_name = NULL;
  END IF;

  IF NEW.unit_name IS NOT NULL AND TRIM(NEW.unit_name) = '' THEN
    SET NEW.unit_name = NULL;
  END IF;

  IF NEW.plate IS NOT NULL AND TRIM(NEW.plate) <> '' THEN
    SET NEW.plate = UPPER(REPLACE(TRIM(NEW.plate), ' ', ''));
    IF NEW.plate NOT REGEXP '(^[A-Z]{3}[0-9]{3}$)|(^[A-Z]{3}[0-9]{2}[A-Z]$)' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de placa invalido en users';
    END IF;
  ELSE
    SET NEW.plate = NULL;
  END IF;

  IF NEW.role = 'residente' AND (NEW.unit_name IS NULL OR TRIM(NEW.unit_name) = '') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un usuario residente debe tener unit_name';
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_users_bu_validate $$
CREATE TRIGGER trg_users_bu_validate
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
  SET NEW.email = LOWER(TRIM(NEW.email));

  IF NEW.full_name IS NOT NULL AND TRIM(NEW.full_name) = '' THEN
    SET NEW.full_name = NULL;
  END IF;

  IF NEW.unit_name IS NOT NULL AND TRIM(NEW.unit_name) = '' THEN
    SET NEW.unit_name = NULL;
  END IF;

  IF NEW.plate IS NOT NULL AND TRIM(NEW.plate) <> '' THEN
    SET NEW.plate = UPPER(REPLACE(TRIM(NEW.plate), ' ', ''));
    IF NEW.plate NOT REGEXP '(^[A-Z]{3}[0-9]{3}$)|(^[A-Z]{3}[0-9]{2}[A-Z]$)' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de placa invalido en users';
    END IF;
  ELSE
    SET NEW.plate = NULL;
  END IF;

  IF NEW.role = 'residente' AND (NEW.unit_name IS NULL OR TRIM(NEW.unit_name) = '') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un usuario residente debe tener unit_name';
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_residents_bi_validate $$
CREATE TRIGGER trg_residents_bi_validate
BEFORE INSERT ON residents
FOR EACH ROW
BEGIN
  SET NEW.full_name = TRIM(NEW.full_name);
  SET NEW.unit_name = TRIM(NEW.unit_name);

  IF NEW.full_name = '' OR NEW.unit_name = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'full_name y unit_name son obligatorios en residents';
  END IF;

  IF NEW.plate IS NOT NULL AND TRIM(NEW.plate) <> '' THEN
    SET NEW.plate = UPPER(REPLACE(TRIM(NEW.plate), ' ', ''));
    IF NEW.plate NOT REGEXP '(^[A-Z]{3}[0-9]{3}$)|(^[A-Z]{3}[0-9]{2}[A-Z]$)' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de placa invalido en residents';
    END IF;
  ELSE
    SET NEW.plate = NULL;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_residents_bu_validate $$
CREATE TRIGGER trg_residents_bu_validate
BEFORE UPDATE ON residents
FOR EACH ROW
BEGIN
  SET NEW.full_name = TRIM(NEW.full_name);
  SET NEW.unit_name = TRIM(NEW.unit_name);

  IF NEW.full_name = '' OR NEW.unit_name = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'full_name y unit_name son obligatorios en residents';
  END IF;

  IF NEW.plate IS NOT NULL AND TRIM(NEW.plate) <> '' THEN
    SET NEW.plate = UPPER(REPLACE(TRIM(NEW.plate), ' ', ''));
    IF NEW.plate NOT REGEXP '(^[A-Z]{3}[0-9]{3}$)|(^[A-Z]{3}[0-9]{2}[A-Z]$)' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de placa invalido en residents';
    END IF;
  ELSE
    SET NEW.plate = NULL;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_parking_spaces_bi_defaults $$
CREATE TRIGGER trg_parking_spaces_bi_defaults
BEFORE INSERT ON parking_spaces
FOR EACH ROW
BEGIN
  DECLARE v_slot INT;

  SET NEW.sector = UPPER(TRIM(NEW.sector));
  SET v_slot = NEW.slot_number;

  IF NEW.code IS NULL OR TRIM(NEW.code) = '' THEN
    SET NEW.code = CONCAT(NEW.sector, '-', LPAD(v_slot, 2, '0'));
  END IF;

  IF NEW.access_allowed IS NULL OR TRIM(NEW.access_allowed) = '' THEN
    IF v_slot BETWEEN 1 AND 10 THEN
      SET NEW.access_allowed = 'Residente';
    ELSEIF v_slot BETWEEN 26 AND 30 THEN
      SET NEW.access_allowed = 'Visitante';
    ELSE
      SET NEW.access_allowed = 'Ambos';
    END IF;
  END IF;

  IF NEW.allowed_vehicle_type IS NULL OR TRIM(NEW.allowed_vehicle_type) = '' THEN
    IF MOD(v_slot, 3) = 0 THEN
      SET NEW.allowed_vehicle_type = 'Moto';
    ELSEIF MOD(v_slot, 5) = 0 THEN
      SET NEW.allowed_vehicle_type = 'Bicicleta';
    ELSE
      SET NEW.allowed_vehicle_type = 'Carro';
    END IF;
  END IF;

  SET NEW.is_occupied = IFNULL(NEW.is_occupied, 0);
END $$

DROP TRIGGER IF EXISTS trg_parking_sessions_bi_validate $$
CREATE TRIGGER trg_parking_sessions_bi_validate
BEFORE INSERT ON parking_sessions
FOR EACH ROW
BEGIN
  DECLARE v_active_count INT DEFAULT 0;
  DECLARE v_space_exists INT DEFAULT 0;
  DECLARE v_busy TINYINT DEFAULT 0;
  DECLARE v_access_rule VARCHAR(15);
  DECLARE v_vehicle_rule VARCHAR(15);
  DECLARE v_counter INT DEFAULT 0;

  SET NEW.plate = UPPER(REPLACE(TRIM(NEW.plate), ' ', ''));
  IF NEW.plate = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La placa es obligatoria';
  END IF;

  IF NEW.plate NOT REGEXP '(^[A-Z]{3}[0-9]{3}$)|(^[A-Z]{3}[0-9]{2}[A-Z]$)' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Formato de placa invalido en parking_sessions';
  END IF;

  IF NEW.unit_name IS NOT NULL AND TRIM(NEW.unit_name) = '' THEN
    SET NEW.unit_name = NULL;
  END IF;

  IF NEW.entered_at IS NULL THEN
    SET NEW.entered_at = CURRENT_TIMESTAMP;
  END IF;

  IF NEW.ticket IS NULL OR TRIM(NEW.ticket) = '' THEN
    UPDATE system_counters
       SET counter_value = counter_value + 1
     WHERE counter_name = 'ticket';

    SELECT counter_value INTO v_counter
      FROM system_counters
     WHERE counter_name = 'ticket';

    SET NEW.ticket = CONCAT('T-', v_counter);
  ELSE
    SET NEW.ticket = UPPER(TRIM(NEW.ticket));
  END IF;

  SELECT COUNT(*)
    INTO v_active_count
    FROM parking_sessions
   WHERE plate = NEW.plate
     AND exited_at IS NULL;

  IF v_active_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La placa ya tiene una sesion activa';
  END IF;

  SELECT COUNT(*), MAX(is_occupied), MAX(access_allowed), MAX(allowed_vehicle_type)
    INTO v_space_exists, v_busy, v_access_rule, v_vehicle_rule
    FROM parking_spaces
   WHERE id = NEW.space_id;

  IF v_space_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupo indicado no existe';
  END IF;

  IF v_busy = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupo indicado ya esta ocupado';
  END IF;

  IF v_access_rule <> 'Ambos' AND v_access_rule <> NEW.access_type THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupo no permite ese tipo de acceso';
  END IF;

  IF v_vehicle_rule <> NEW.vehicle_type THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupo no permite ese tipo de vehiculo';
  END IF;

  IF NEW.access_type = 'Visitante' THEN
    IF NEW.visitor_name IS NULL OR TRIM(NEW.visitor_name) = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'visitor_name es obligatorio para visitantes';
    END IF;
    IF NEW.visitor_document IS NULL OR TRIM(NEW.visitor_document) = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'visitor_document es obligatorio para visitantes';
    END IF;
    IF NEW.authorized_by_resident_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'authorized_by_resident_id es obligatorio para visitantes';
    END IF;
    IF NEW.authorized_ok <> 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El visitante debe quedar autorizado';
    END IF;
  ELSE
    SET NEW.authorized_by_resident_id = NULL;
    SET NEW.authorized_ok = 0;
    SET NEW.visitor_name = NULL;
    SET NEW.visitor_document = NULL;
    SET NEW.visitor_notes = NULL;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_parking_sessions_ai_occupy_and_log $$
CREATE TRIGGER trg_parking_sessions_ai_occupy_and_log
AFTER INSERT ON parking_sessions
FOR EACH ROW
BEGIN
  DECLARE v_space_code VARCHAR(10);
  DECLARE v_sector CHAR(1);
  DECLARE v_spot_rule VARCHAR(15);
  DECLARE v_authorized_by VARCHAR(120);

  UPDATE parking_spaces
     SET is_occupied = 1,
         current_plate = NEW.plate
   WHERE id = NEW.space_id;

  SELECT code, sector, access_allowed
    INTO v_space_code, v_sector, v_spot_rule
    FROM parking_spaces
   WHERE id = NEW.space_id;

  IF NEW.authorized_by_resident_id IS NOT NULL THEN
    SELECT CONCAT(full_name, ' • ', unit_name)
      INTO v_authorized_by
      FROM residents
     WHERE id = NEW.authorized_by_resident_id;
  ELSE
    SET v_authorized_by = NULL;
  END IF;

  INSERT INTO movement_log (
    session_id, movement_ts, event_type, status, plate, ticket, access_type,
    unit_name, vehicle_type, space_code, sector, spot_rule,
    visitor_name, visitor_document, authorized_by, notes, charged_amount
  ) VALUES (
    NEW.id, NEW.entered_at, 'Entrada', 'Pendiente', NEW.plate, NEW.ticket, NEW.access_type,
    NEW.unit_name, NEW.vehicle_type, v_space_code, v_sector, v_spot_rule,
    NEW.visitor_name, NEW.visitor_document, v_authorized_by, NEW.visitor_notes, NULL
  );
END $$

DROP TRIGGER IF EXISTS trg_parking_sessions_bu_exit_calc $$
CREATE TRIGGER trg_parking_sessions_bu_exit_calc
BEFORE UPDATE ON parking_sessions
FOR EACH ROW
BEGIN
  DECLARE v_minutes INT DEFAULT NULL;
  DECLARE v_rate DECIMAL(10,2) DEFAULT 0;

  IF NEW.exited_at IS NOT NULL AND OLD.exited_at IS NULL THEN
    IF NEW.exited_at < OLD.entered_at THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de salida no puede ser menor a la de entrada';
    END IF;

    IF NEW.payment_status IS NULL OR NEW.payment_status = 'Pendiente' THEN
      SET NEW.payment_status = 'Pagado';
    END IF;

    SET v_minutes = GREATEST(1, TIMESTAMPDIFF(MINUTE, OLD.entered_at, NEW.exited_at));
    SET NEW.minutes_parked = v_minutes;

    SELECT hour_rate INTO v_rate
      FROM vehicle_rates
     WHERE vehicle_type = OLD.vehicle_type
     LIMIT 1;

    IF NEW.charged_amount IS NULL THEN
      SET NEW.charged_amount = GREATEST(1, CEIL(v_minutes / 60)) * IFNULL(v_rate, 0);
    END IF;
  END IF;
END $$

DROP TRIGGER IF EXISTS trg_parking_sessions_au_release_and_log $$
CREATE TRIGGER trg_parking_sessions_au_release_and_log
AFTER UPDATE ON parking_sessions
FOR EACH ROW
BEGIN
  DECLARE v_space_code VARCHAR(10);
  DECLARE v_sector CHAR(1);
  DECLARE v_spot_rule VARCHAR(15);
  DECLARE v_authorized_by VARCHAR(120);

  IF NEW.exited_at IS NOT NULL AND OLD.exited_at IS NULL THEN
    UPDATE parking_spaces
       SET is_occupied = 0,
           current_plate = NULL
     WHERE id = NEW.space_id;

    SELECT code, sector, access_allowed
      INTO v_space_code, v_sector, v_spot_rule
      FROM parking_spaces
     WHERE id = NEW.space_id;

    IF NEW.authorized_by_resident_id IS NOT NULL THEN
      SELECT CONCAT(full_name, ' • ', unit_name)
        INTO v_authorized_by
        FROM residents
       WHERE id = NEW.authorized_by_resident_id;
    ELSE
      SET v_authorized_by = NULL;
    END IF;

    INSERT INTO movement_log (
      session_id, movement_ts, event_type, status, plate, ticket, access_type,
      unit_name, vehicle_type, space_code, sector, spot_rule,
      visitor_name, visitor_document, authorized_by, notes, charged_amount
    ) VALUES (
      NEW.id, NEW.exited_at, 'Salida', NEW.payment_status, NEW.plate, NEW.ticket, NEW.access_type,
      NEW.unit_name, NEW.vehicle_type, v_space_code, v_sector, v_spot_rule,
      NEW.visitor_name, NEW.visitor_document, v_authorized_by, NEW.visitor_notes, NEW.charged_amount
    );
  END IF;
END $$

DELIMITER ;

INSERT INTO vehicle_rates(vehicle_type, hour_rate, day_rate, month_rate)
VALUES
  ('Carro', 3000, 20000, 180000),
  ('Moto', 2000, 15000, 120000),
  ('Bicicleta', 1000, 8000, 60000);

INSERT INTO users(full_name, email, pass_hash, role, unit_name, plate)
VALUES
  ('Administrador', 'admin@goresidentgo.com', 'h969161597', 'admin', NULL, NULL),
  ('Porteria', 'porteria@goresidentgo.com', 'h809871892', 'porteria', NULL, NULL),
  ('Usuario Residente', 'residente@goresidentgo.com', 'h310981379', 'residente', 'Torre 1 - Apto 302', 'ABC123');

INSERT INTO residents(user_id, full_name, unit_name, plate)
VALUES
  ((SELECT id FROM users WHERE email = 'residente@goresidentgo.com'), 'María Gómez', 'Torre 1 - Apto 302', 'ABC123'),
  (NULL, 'Carlos Ruiz', 'Torre 2 - Apto 504', 'MOT777'),
  (NULL, 'Ana Pardo', 'Torre 3 - Apto 101', NULL);

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_seed_parking_spaces $$
CREATE PROCEDURE sp_seed_parking_spaces()
BEGIN
  DECLARE v_sector_index INT DEFAULT 1;
  DECLARE v_sector CHAR(1);
  DECLARE v_slot INT;

  WHILE v_sector_index <= 3 DO
    SET v_sector = ELT(v_sector_index, 'A', 'B', 'C');
    SET v_slot = 1;

    WHILE v_slot <= 30 DO
      INSERT INTO parking_spaces(sector, slot_number, allowed_vehicle_type, access_allowed)
      VALUES (v_sector, v_slot, NULL, NULL);
      SET v_slot = v_slot + 1;
    END WHILE;

    SET v_sector_index = v_sector_index + 1;
  END WHILE;
END $$
DELIMITER ;

CALL sp_seed_parking_spaces();
DROP PROCEDURE sp_seed_parking_spaces;

CREATE VIEW vw_dashboard AS
SELECT
  (SELECT COUNT(*) FROM parking_spaces) AS total_cupos,
  (SELECT COUNT(*) FROM parking_spaces WHERE is_occupied = 0) AS cupos_disponibles,
  (SELECT COUNT(*) FROM parking_spaces WHERE is_occupied = 1) AS vehiculos_dentro,
  (SELECT COUNT(*) FROM movement_log WHERE event_type = 'Entrada') AS tickets_generados,
  ROUND(
    (
      (SELECT COUNT(*) FROM parking_spaces WHERE is_occupied = 1)
      / NULLIF((SELECT COUNT(*) FROM parking_spaces), 0)
    ) * 100,
    0
  ) AS ocupacion_pct;
