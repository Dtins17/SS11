-- PHÂN TÍCH

-- INPUT:
-- p_patient_id (INT)       : có thể NULL
-- p_phone (VARCHAR)        : có thể NULL

-- OUTPUT:
-- p_total_debt (DECIMAL)   : tổng nợ
-- p_message (VARCHAR)      : thông báo

-- => dùng IN + OUT


--  Đề xuaasts 2 cách

-- Cách 1: IF / ELSE
-- - nếu có ID → tìm theo ID
-- - nếu không có ID nhưng có phone → tìm theo phone
-- - nếu có cả 2 → ưu tiên ID

-- Cách 2: WHERE linh hoạt
-- SELECT ... WHERE (id = p_id OR phone = p_phone)


-- SO SÁNH 

-- Cách 1 (IF ELSE):
-- + rõ ràng, dễ hiểu
-- + kiểm soát tốt từng trường hợp
-- - code dài hơn

-- Cách 2 (OR):
-- + code ngắn
-- - dễ sai nếu cả 2 NULL
-- - khó kiểm soát logic ưu tiên

-- => CHỌN CÁCH 1 (an toàn, dễ debug)


-- Thiết kế luồng 
-- B1: nếu cả ID và phone đều NULL → báo lỗi
-- B2: nếu có ID → tìm theo ID
-- B3: nếu không có ID → tìm theo phone
-- B4: nếu không tìm thấy → trả 0 + thông báo
-- B5: nếu tìm thấy → trả tổng nợ + OK


-- Xóa nếu đã tồn tại
DROP PROCEDURE IF EXISTS GetPatientDebt;

DELIMITER //

CREATE PROCEDURE GetPatientDebt(
    IN p_patient_id INT,
    IN p_phone VARCHAR(20),
    OUT p_total_debt DECIMAL(15,2),
    OUT p_message VARCHAR(255)
)
BEGIN

    DECLARE v_count INT DEFAULT 0;

    -- 1. chặn NULL cả 2
    IF p_patient_id IS NULL AND p_phone IS NULL THEN
        SET p_total_debt = 0;
        SET p_message = 'Loi: Thieu thong tin tra cuu';

    ELSE

        -- 2. ưu tiên tìm theo ID
        IF p_patient_id IS NOT NULL THEN

            SELECT COUNT(*) INTO v_count
            FROM patients
            WHERE id = p_patient_id;

            IF v_count = 0 THEN
                SET p_total_debt = 0;
                SET p_message = 'Khong tim thay';
            ELSE
                SELECT total_debt INTO p_total_debt
                FROM patients
                WHERE id = p_patient_id;

                SET p_message = 'Tim thanh cong';
            END IF;

        -- 3. nếu không có ID thì tìm theo phone
        ELSE

            SELECT COUNT(*) INTO v_count
            FROM patients
            WHERE phone = p_phone;

            IF v_count = 0 THEN
                SET p_total_debt = 0;
                SET p_message = 'Khong tim thay';
            ELSE
                SELECT total_debt INTO p_total_debt
                FROM patients
                WHERE phone = p_phone;

                SET p_message = 'Tim thanh cong';
            END IF;

        END IF;

    END IF;

END //

DELIMITER ;


SET @debt = 0;
SET @msg = '';

-- 1. chỉ ID
CALL GetPatientDebt(1, NULL, @debt, @msg);
SELECT @debt, @msg;

-- 2. chỉ phone
CALL GetPatientDebt(NULL, '0901234567', @debt, @msg);
SELECT @debt, @msg;

-- 3. NULL cả 2
CALL GetPatientDebt(NULL, NULL, @debt, @msg);
SELECT @debt, @msg;

-- 4. không tồn tại
CALL GetPatientDebt(9999, NULL, @debt, @msg);
SELECT @debt, @msg;