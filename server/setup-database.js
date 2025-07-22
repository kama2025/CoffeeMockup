const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupDatabase() {
  let connection;
  
  try {
    // Подключение без указания базы данных для её создания
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || ''
    });

    console.log('🔌 Подключение к MySQL установлено');

    // Создание базы данных
    await connection.execute(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME || 'coffee_app'} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
    console.log('📊 База данных создана');

    // Переключение на созданную базу данных
    await connection.execute(`USE ${process.env.DB_NAME || 'coffee_app'}`);

    // Создание таблицы категорий
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        icon VARCHAR(50) NOT NULL,
        display_order INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    // Создание таблицы товаров
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        category_id INT NOT NULL,
        name VARCHAR(200) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL,
        image_url VARCHAR(500),
        available BOOLEAN DEFAULT true,
        featured BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    `);

    // Создание таблицы заказов
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_number VARCHAR(50) UNIQUE NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        status ENUM('placed', 'preparing', 'ready', 'completed', 'cancelled') DEFAULT 'placed',
        customer_name VARCHAR(100),
        customer_phone VARCHAR(20),
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    // Создание таблицы позиций заказа
    await connection.execute(`
      CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL DEFAULT 1,
        price DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    `);

    console.log('📋 Таблицы созданы');

    // Вставка тестовых категорий
    await connection.execute(`
      INSERT IGNORE INTO categories (id, name, icon, display_order) VALUES
      (1, 'Кофе', '☕️', 1),
      (2, 'Десерты', '🍰', 2),
      (3, 'Закуски', '🥪', 3),
      (4, 'Напитки', '🥤', 4)
    `);

    // Вставка тестовых товаров
    await connection.execute(`
      INSERT IGNORE INTO products (id, category_id, name, description, price, image_url, featured) VALUES
      -- Кофе
      (1, 1, 'Эспрессо', 'Классический итальянский кофе с насыщенным вкусом', 150.00, 'https://example.com/espresso.jpg', true),
      (2, 1, 'Американо', 'Эспрессо с горячей водой, мягкий и ароматный', 180.00, 'https://example.com/americano.jpg', false),
      (3, 1, 'Капучино', 'Эспрессо с взбитым молоком и воздушной пенкой', 220.00, 'https://example.com/cappuccino.jpg', true),
      (4, 1, 'Латте', 'Нежный кофе с большим количеством молока', 250.00, 'https://example.com/latte.jpg', false),
      (5, 1, 'Раф', 'Сливочный кофе по-русски с ванилью', 280.00, 'https://example.com/raf.jpg', true),
      (6, 1, 'Флэт Вайт', 'Двойной эспрессо с микропенкой', 270.00, 'https://example.com/flatwhite.jpg', false),
      
      -- Десерты
      (7, 2, 'Чизкейк', 'Нежный творожный торт с ягодным соусом', 320.00, 'https://example.com/cheesecake.jpg', true),
      (8, 2, 'Тирамису', 'Итальянский десерт с кофе и маскарпоне', 350.00, 'https://example.com/tiramisu.jpg', true),
      (9, 2, 'Эклер', 'Заварное пирожное с кремом', 180.00, 'https://example.com/eclair.jpg', false),
      (10, 2, 'Макарон', 'Французское миндальное печенье', 120.00, 'https://example.com/macaron.jpg', false),
      (11, 2, 'Панна-котта', 'Итальянский молочный десерт', 290.00, 'https://example.com/pannacotta.jpg', false),
      
      -- Закуски
      (12, 3, 'Круассан с ветчиной', 'Свежая французская выпечка с начинкой', 200.00, 'https://example.com/croissant.jpg', false),
      (13, 3, 'Сэндвич клаб', 'С курицей, беконом и овощами', 350.00, 'https://example.com/sandwich.jpg', true),
      (14, 3, 'Салат Цезарь', 'Свежий салат с курицей и сухариками', 420.00, 'https://example.com/caesar.jpg', false),
      (15, 3, 'Багет с лососем', 'Свежий багет с слабосоленым лососем', 450.00, 'https://example.com/salmon.jpg', true),
      
      -- Напитки
      (16, 4, 'Какао', 'Горячий шоколадный напиток', 180.00, 'https://example.com/cocoa.jpg', false),
      (17, 4, 'Чай Earl Grey', 'Классический английский чай', 150.00, 'https://example.com/tea.jpg', false),
      (18, 4, 'Смузи манго', 'Освежающий фруктовый смузи', 220.00, 'https://example.com/smoothie.jpg', true),
      (19, 4, 'Лимонад', 'Домашний лимонад с мятой', 200.00, 'https://example.com/lemonade.jpg', false)
    `);

    console.log('✅ Тестовые данные добавлены');
    console.log('🎉 База данных успешно настроена!');
    
    // Показать статистику
    const [categoriesCount] = await connection.execute('SELECT COUNT(*) as count FROM categories');
    const [productsCount] = await connection.execute('SELECT COUNT(*) as count FROM products');
    
    console.log(`📊 Статистика:`);
    console.log(`   Категории: ${categoriesCount[0].count}`);
    console.log(`   Товары: ${productsCount[0].count}`);

  } catch (error) {
    console.error('❌ Ошибка настройки базы данных:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 Соединение с базой данных закрыто');
    }
  }
}

// Запуск настройки
setupDatabase(); 