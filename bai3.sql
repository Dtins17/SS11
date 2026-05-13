
-- INPUT:
-- - p_total_cost: tổng chi phí
-- - p_patient_type: loại bệnh nhân (BHYT, VIP, THUONG)

-- OUTPUT:
-- - p_final_amount: tiền phải trả
-- - p_message: thông báo


--  GIẢI PHÁP & CÁC BƯỚC

-- Bước 1: Validate dữ liệu đầu vào
--   - Nếu p_total_cost < 0 → lỗi
--   - Trả về:
--       p_final_amount = 0
--       p_message = 'Lỗi: Chi phí không hợp lệ'

-- Bước 2: Xử lý theo loại bệnh nhân
--   - BHYT   → trả 20% chi phí
--   - VIP    → giảm 10% (trả 90%)
--   - THUONG → trả 100%


-- Xóa nếu đã có
DROP PROCEDURE IF EXISTS CalculateHospitalBill;

DELIMITER //

CREATE PROCEDURE CalculateHospitalBill(
    IN p_total_cost DECIMAL(15,2),
    IN p_patient_type VARCHAR(20),
    OUT p_final_amount DECIMAL(15,2),
    OUT p_message VARCHAR(255)
)
BEGIN

    -- nếu nhập chi phí âm thì báo lỗi
    IF p_total_cost < 0 THEN
        SET p_final_amount = 0;
        SET p_message = 'Loi: Chi phi khong hop le';

    ELSE

        -- tính tiền theo loại bệnh nhân
        CASE p_patient_type

            WHEN 'BHYT' THEN
                -- chỉ trả 20%
                SET p_final_amount = p_total_cost * 0.2;

            WHEN 'VIP' THEN
                -- giảm 10% -> trả 90%
                SET p_final_amount = p_total_cost * 0.9;

            WHEN 'THUONG' THEN
                -- trả đủ 100%
                SET p_final_amount = p_total_cost;

            ELSE
                -- nhập sai loại
                SET p_final_amount = 0;
                SET p_message = 'Loi: Dien benh nhan khong hop le';

        END CASE;

        -- nếu không lỗi thì báo thành công
        IF p_message IS NULL THEN
            SET p_message = 'Da tinh toan xong';
        END IF;

    END IF;

END //

DELIMITER ;


-- =========================
-- TEST
-- =========================

SET @money = 0;
SET @msg = '';

-- BHYT
CALL CalculateHospitalBill(1000000, 'BHYT', @money, @msg);
SELECT @money, @msg;

-- VIP
CALL CalculateHospitalBill(1000000, 'VIP', @money, @msg);
SELECT @money, @msg;

-- THUONG
CALL CalculateHospitalBill(1000000, 'THUONG', @money, @msg);
SELECT @money, @msg;

-- lỗi (âm)
CALL CalculateHospitalBill(-500000, 'VIP', @money, @msg);
SELECT @money, @msg;