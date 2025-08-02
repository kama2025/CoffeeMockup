-- ======================================
-- КОФЕЙНАЯ СИСТЕМА - MySQL База Данных
-- Совместимость с новым APIService.swift
-- ======================================

CREATE DATABASE IF NOT EXISTS coffeeshop_db
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE coffeeshop_db;

-- Удаление существующих таблиц (в правильном порядке)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;

-- ======================================
-- КАТЕГОРИИ
-- ======================================

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(100) NOT NULL DEFAULT 'folder.fill',
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_display_order (display_order),
    INDEX idx_active (is_active)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ======================================
-- ТОВАРЫ
-- ======================================

CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(500),
    available BOOLEAN DEFAULT TRUE,
    featured BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_category (category_id),
    INDEX idx_available (available),
    INDEX idx_featured (featured),
    INDEX idx_display_order (display_order)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ======================================
-- ЗАКАЗЫ
-- ======================================

CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status ENUM('placed', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled') DEFAULT 'placed',
    customer_name VARCHAR(100),
    customer_phone VARCHAR(20),
    notes TEXT,
    items_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_created (created_at),
    INDEX idx_order_number (order_number)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ======================================
-- ПОЗИЦИИ ЗАКАЗА
-- ======================================

CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price DECIMAL(10, 2) NOT NULL,
    product_name VARCHAR(150),
    product_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id),
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ======================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ======================================

-- Категории товаров
INSERT INTO categories (name, icon, display_order) VALUES
('Кофе', 'cup.and.saucer.fill', 1),
('Чай', 'leaf.fill', 2),
('Десерты', 'birthday.cake.fill', 3),
('Холодные напитки', 'drop.fill', 4),
('Завтраки', 'sun.max.fill', 5);

-- Товары
INSERT INTO products (category_id, name, description, price, featured, display_order) VALUES
-- Кофе (category_id = 1)
(1, 'Эспрессо', 'Классический итальянский эспрессо из отборных зерен арабики', 120.00, TRUE, 1),
(1, 'Американо', 'Эспрессо с горячей водой для мягкого вкуса', 150.00, TRUE, 2),
(1, 'Капучино', 'Эспрессо с взбитым молоком и воздушной пенкой', 220.00, TRUE, 3),
(1, 'Латте', 'Нежный эспрессо с большим количеством молока', 250.00, TRUE, 4),
(1, 'Флэт Уайт', 'Двойной эспрессо с микропенкой', 280.00, FALSE, 5),
(1, 'Мокка', 'Кофе с шоколадом и взбитыми сливками', 290.00, FALSE, 6),

-- Чай (category_id = 2)
(2, 'Черный чай', 'Классический цейлонский черный чай', 100.00, FALSE, 1),
(2, 'Зеленый чай', 'Освежающий китайский зеленый чай', 120.00, FALSE, 2),
(2, 'Травяной чай', 'Ароматный микс полезных трав', 140.00, FALSE, 3),
(2, 'Чай с лимоном', 'Черный чай с свежим лимоном', 130.00, FALSE, 4),
(2, 'Масала чай', 'Пряный индийский чай со специями', 180.00, TRUE, 5),

-- Десерты (category_id = 3)
(3, 'Круассан классический', 'Свежий французский круассан', 180.00, TRUE, 1),
(3, 'Круассан с шоколадом', 'Круассан с темным шоколадом', 220.00, TRUE, 2),
(3, 'Чизкейк Нью-Йорк', 'Нежный творожный торт в американском стиле', 320.00, TRUE, 3),
(3, 'Маффин черничный', 'Домашний кекс со свежей черникой', 200.00, FALSE, 4),
(3, 'Тирамису', 'Классический итальянский десерт', 350.00, TRUE, 5),
(3, 'Эклер', 'Заварное пирожное с кремом', 190.00, FALSE, 6),

-- Холодные напитки (category_id = 4)
(4, 'Лимонад домашний', 'Свежий лимонад собственного приготовления', 180.00, FALSE, 1),
(4, 'Айс-кофе', 'Холодный кофе со льдом', 200.00, TRUE, 2),
(4, 'Фраппе', 'Взбитый холодный кофе с молоком', 250.00, TRUE, 3),
(4, 'Холодный чай', 'Освежающий чай со льдом и мятой', 160.00, FALSE, 4),
(4, 'Смузи ягодный', 'Микс свежих ягод и йогурта', 290.00, TRUE, 5),

-- Завтраки (category_id = 5)
(5, 'Сэндвич с курицей', 'Свежий сэндвич с грудкой курицы', 320.00, TRUE, 1),
(5, 'Омлет классический', 'Пушистый омлет из трех яиц', 250.00, FALSE, 2),
(5, 'Гранола с йогуртом', 'Домашняя гранола с греческим йогуртом', 280.00, TRUE, 3),
(5, 'Тост с авокадо', 'Цельнозерновой хлеб с авокадо', 290.00, TRUE, 4);

-- Тестовые заказы
INSERT INTO orders (order_number, total_price, status, customer_name, customer_phone, notes, items_count) VALUES
('ORD-001', 540.00, 'completed', 'Анна Петрова', '+7999123456', 'Без сахара', 2),
('ORD-002', 320.00, 'preparing', 'Иван Смирнов', '+7999123457', NULL, 1),
('ORD-003', 720.00, 'ready', 'Мария Кофеина', '+7999123458', 'На вынос', 3);

-- Позиции тестовых заказов
INSERT INTO order_items (order_id, product_id, quantity, price, product_name, product_description) VALUES
-- Заказ 1
(1, 3, 1, 220.00, 'Капучино', 'Эспрессо с взбитым молоком и воздушной пенкой'),
(1, 9, 1, 320.00, 'Чизкейк Нью-Йорк', 'Нежный творожный торт в американском стиле'),

-- Заказ 2
(2, 13, 1, 320.00, 'Сэндвич с курицей', 'Свежий сэндвич с грудкой курицы'),

-- Заказ 3
(3, 4, 2, 250.00, 'Латте', 'Нежный эспрессо с большим количеством молока'),
(3, 8, 1, 220.00, 'Круассан с шоколадом', 'Круассан с темным шоколадом');

-- ======================================
-- ПОЛЕЗНЫЕ ПРЕДСТАВЛЕНИЯ
-- ======================================

-- Товары с информацией о категории
CREATE VIEW products_with_category AS
SELECT 
    p.*,
    c.name as category_name,
    c.icon as category_icon
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE p.available = TRUE
ORDER BY c.display_order, p.display_order;

-- Заказы с детальной информацией
CREATE VIEW orders_detailed AS
SELECT 
    o.*,
    COUNT(oi.id) as actual_items_count,
    SUM(oi.quantity * oi.price) as calculated_total,
    GROUP_CONCAT(CONCAT(oi.product_name, ' x', oi.quantity) SEPARATOR ', ') as items_summary
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id
ORDER BY o.created_at DESC;

-- ======================================
-- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ
-- ======================================

-- Составные индексы для частых запросов
CREATE INDEX idx_products_category_featured ON products(category_id, featured);
CREATE INDEX idx_products_available_featured ON products(available, featured);
CREATE INDEX idx_orders_status_date ON orders(status, created_at);

-- ======================================
-- ТРИГГЕРЫ ДЛЯ АВТОМАТИЗАЦИИ
-- ======================================

-- Автоматическое обновление счетчика позиций в заказе
DELIMITER $$

CREATE TRIGGER update_order_items_count_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders 
    SET items_count = (
        SELECT COUNT(*) 
        FROM order_items 
        WHERE order_id = NEW.order_id
    )
    WHERE id = NEW.order_id;
END$$

CREATE TRIGGER update_order_items_count_delete
AFTER DELETE ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders 
    SET items_count = (
        SELECT COUNT(*) 
        FROM order_items 
        WHERE order_id = OLD.order_id
    )
    WHERE id = OLD.order_id;
END$$

DELIMITER ;

-- ======================================
-- ЗАВЕРШЕНИЕ ИНИЦИАЛИЗАЦИИ
-- ======================================

-- Обновляем счетчики для существующих заказов
UPDATE orders o 
SET items_count = (
    SELECT COUNT(*) 
    FROM order_items oi 
    WHERE oi.order_id = o.id
);

-- Проверка целостности данных
SELECT 
    'Категории' as table_name, 
    COUNT(*) as count 
FROM categories
UNION ALL
SELECT 
    'Товары', 
    COUNT(*) 
FROM products
UNION ALL
SELECT 
    'Заказы', 
    COUNT(*) 
FROM orders
UNION ALL
SELECT 
    'Позиции заказов', 
    COUNT(*) 
FROM order_items; 