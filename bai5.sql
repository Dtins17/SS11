-- Thiết kế giao tiếp
-- Procedure phụ: trả về bed_id → dùng OUT
-- Procedure chính:
-- IN: patient_id, dept_id
-- OUT:
-- new_bed_id
-- message

-- Master gọi Sub và “hứng” kết quả qua OUT

-- Giả sử bảng
-- patients(id, status, bed_id)
-- beds(id, dept_id, is_occupied)
-- departments(id, name)

-- Procedure phụ: tìm giường trống 
DROP PROCEDURE IF EXISTS FindAvailableBed;

DELIMITER //

CREATE PROCEDURE FindAvailableBed(
    IN p_dept_id INT,
    OUT p_bed_id INT
)
BEGIN
    -- tìm 1 giường trống trong khoa
    SELECT id INTO p_bed_id
    FROM beds
    WHERE dept_id = p_dept_id
      AND is_occupied = 0
    LIMIT 1;

    -- nếu không có thì sẽ trả NULL
END //

DELIMITER ;

-- Procedure chính (MASTER)
DROP PROCEDURE IF EXISTS TransferPatientBed;

DELIMITER //

CREATE PROCEDURE TransferPatientBed(
    IN p_patient_id INT,
    IN p_dept_id INT,
    OUT p_new_bed_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN

    DECLARE v_status VARCHAR(50);
    DECLARE v_old_bed INT;
    DECLARE v_dept_name VARCHAR(100);

    -- lấy trạng thái bệnh nhân
    SELECT status, bed_id INTO v_status, v_old_bed
    FROM patients
    WHERE id = p_patient_id;

    -- CHECK 1: đã xuất viện chưa
    IF v_status = 'Completed' THEN
        SET p_new_bed_id = NULL;
        SET p_message = 'Tu choi: Benh nhan da xuat vien';

    ELSE

        -- CHECK 2: khoa tồn tại không
        SELECT name INTO v_dept_name
        FROM departments
        WHERE id = p_dept_id;

        IF v_dept_name IS NULL THEN
            SET p_new_bed_id = NULL;
            SET p_message = 'Loi: Khoa khong ton tai';

        ELSE

            -- gọi procedure phụ
            CALL FindAvailableBed(p_dept_id, p_new_bed_id);

            -- CHECK 3: hết giường
            IF p_new_bed_id IS NULL THEN
                SET p_message = CONCAT('Tu choi: Khoa ', v_dept_name, ' da het giuong');

            ELSE

                -- bắt đầu transaction để tránh đụng độ
                START TRANSACTION;

                -- 1. giải phóng giường cũ
                UPDATE beds
                SET is_occupied = 0
                WHERE id = v_old_bed;

                -- 2. gán giường mới
                UPDATE patients
                SET bed_id = p_new_bed_id
                WHERE id = p_patient_id;

                -- 3. khóa giường mới
                UPDATE beds
                SET is_occupied = 1
                WHERE id = p_new_bed_id;

                COMMIT;

                SET p_message = 'Chuyen giuong thanh cong';

            END IF;

        END IF;

    END IF;

END //

DELIMITER ;

SET @bed = NULL;
SET @msg = '';

-- 1. thành công
CALL TransferPatientBed(1, 2, @bed, @msg);
SELECT @bed, @msg;

-- 2. hết giường
CALL TransferPatientBed(1, 99, @bed, @msg); -- dept đầy
SELECT @bed, @msg;

-- 3. bệnh nhân đã xuất viện
CALL TransferPatientBed(2, 1, @bed, @msg); -- patient status = Completed
SELECT @bed, @msg;

-- 4. khoa không tồn tại
CALL TransferPatientBed(1, 999, @bed, @msg);
SELECT @bed, @msg; 