-- Tái hiện lỗi: nhân viên nhập nhầm số lượng âm
CALL AddInventory(10, -500);

-- Giải thích:
-- Procedure hiện tại KHÔNG kiểm tra dữ liệu đầu vào (p_quantity)
-- Khi truyền vào số âm (-500), phép cộng sẽ trở thành:
-- stock_quantity = stock_quantity + (-500)
-- => thực chất là TRỪ đi 500 → gây thất thoát vật tư trong kho



-- PHẦN B - SỬA LỖI


-- 1. Xóa thủ tục cũ để tránh xung đột
DROP PROCEDURE IF EXISTS AddInventory;


-- 2. Tạo lại thủ tục với validate dữ liệu
DELIMITER //

CREATE PROCEDURE AddInventory(
    IN p_item_id INT,
    IN p_quantity INT
)
BEGIN

-- BƯỚC 1: VALIDATE DỮ LIỆU ĐẦU VÀO

    -- Rule hệ thống:
    -- Số lượng nhập kho PHẢI > 0
    -- => chặn cả số âm và số 0

    IF p_quantity <= 0 THEN
        -- SIGNAL dùng để ném lỗi thủ công trong MySQL
        -- SQLSTATE '45000' là mã lỗi do user định nghĩa
        -- Khi gặp SIGNAL:
        --  + Dừng procedure ngay lập tức
        --  + Không thực hiện UPDATE
        --  + Trả lỗi về cho ứng dụng
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'So luong nhap kho phai lon hon 0!';
        
-- KIỂM TRA ITEM CÓ TỒN TẠI KHÔNG

    ELSEIF NOT EXISTS (
        SELECT 1 
        FROM Inventory 
        WHERE item_id = p_item_id
    ) THEN

        -- Tránh trường hợp nhập vào item_id không tồn tại
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item khong ton tai trong kho!';

-- BƯỚC 2: THỰC HIỆN CẬP NHẬT (CHỈ KHI HỢP LỆ)

    ELSE
        -- Lúc này dữ liệu đã hợp lệ:
        -- + p_quantity > 0
        -- + item tồn tại
        -- => an toàn để cộng tồn kho

        UPDATE Inventory
        SET stock_quantity = stock_quantity + p_quantity
        WHERE item_id = p_item_id;

    END IF;

END //

DELIMITER ;
-- Kết quả sau fix 
-- Hợp lệ → cộng kho
CALL AddInventory(10, 100);

-- Không hợp lệ → bị chặn
CALL AddInventory(10, -500);

-- Không hợp lệ → bị chặn
CALL AddInventory(10, 0);
