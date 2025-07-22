const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 100, // максимум 100 запросов за окно
  message: 'Слишком много запросов с этого IP, попробуйте позже.'
});
app.use('/api/', limiter);

// Создание пула соединений MySQL
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'coffee_app',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  acquireTimeout: 60000,
  timeout: 60000,
  charset: 'utf8mb4'
});

// Проверка подключения к базе данных
async function checkDatabaseConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Подключение к MySQL успешно установлено');
    connection.release();
  } catch (error) {
    console.error('❌ Ошибка подключения к MySQL:', error.message);
    process.exit(1);
  }
}

// API Routes

// Главная страница
app.get('/', (req, res) => {
  res.json({
    message: '☕ Coffee App API',
    version: '1.0.0',
    status: 'active',
    endpoints: {
      categories: 'GET /api/categories',
      products: 'GET /api/products',
      productsByCategory: 'GET /api/products/category/:id',
      featuredProducts: 'GET /api/products/featured',
      createOrder: 'POST /api/orders',
      getOrders: 'GET /api/orders'
    }
  });
});

// Получить все категории
app.get('/api/categories', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM categories ORDER BY display_order, name'
    );
    res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Ошибка получения категорий:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения категорий'
    });
  }
});

// Получить все товары
app.get('/api/products', async (req, res) => {
  try {
    const { category_id, search, limit = 50, offset = 0 } = req.query;
    
    let query = `
      SELECT p.*, c.name as category_name, c.icon as category_icon
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.available = true
    `;
    const params = [];

    if (category_id) {
      query += ' AND p.category_id = ?';
      params.push(category_id);
    }

    if (search) {
      query += ' AND (p.name LIKE ? OR p.description LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY p.featured DESC, p.name LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [rows] = await pool.execute(query, params);
    
    res.json({
      success: true,
      data: rows,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: rows.length
      }
    });
  } catch (error) {
    console.error('Ошибка получения товаров:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения товаров'
    });
  }
});

// Получить товары по категории
app.get('/api/products/category/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.execute(
      `SELECT p.*, c.name as category_name, c.icon as category_icon
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.category_id = ? AND p.available = true
       ORDER BY p.featured DESC, p.name`,
      [id]
    );
    
    res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Ошибка получения товаров категории:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения товаров категории'
    });
  }
});

// Получить рекомендуемые товары
app.get('/api/products/featured', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT p.*, c.name as category_name, c.icon as category_icon
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.featured = true AND p.available = true
       ORDER BY p.name
       LIMIT 10`
    );
    
    res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('Ошибка получения рекомендуемых товаров:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения рекомендуемых товаров'
    });
  }
});

// Создать заказ
app.post('/api/orders', async (req, res) => {
  const connection = await pool.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { items, customer_name, customer_phone, notes } = req.body;
    
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Заказ должен содержать хотя бы один товар'
      });
    }

    // Генерация номера заказа
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 5).toUpperCase()}`;
    
    // Вычисление общей стоимости
    let totalPrice = 0;
    const validatedItems = [];
    
    for (const item of items) {
      const [productRows] = await connection.execute(
        'SELECT id, name, price, available FROM products WHERE id = ?',
        [item.product_id]
      );
      
      if (productRows.length === 0) {
        throw new Error(`Товар с ID ${item.product_id} не найден`);
      }
      
      const product = productRows[0];
      if (!product.available) {
        throw new Error(`Товар "${product.name}" недоступен`);
      }
      
      const quantity = parseInt(item.quantity) || 1;
      const itemTotal = product.price * quantity;
      totalPrice += itemTotal;
      
      validatedItems.push({
        product_id: product.id,
        quantity: quantity,
        price: product.price
      });
    }

    // Создание заказа
    const [orderResult] = await connection.execute(
      `INSERT INTO orders (order_number, total_price, customer_name, customer_phone, notes)
       VALUES (?, ?, ?, ?, ?)`,
      [orderNumber, totalPrice, customer_name, customer_phone, notes]
    );
    
    const orderId = orderResult.insertId;

    // Добавление позиций заказа
    for (const item of validatedItems) {
      await connection.execute(
        `INSERT INTO order_items (order_id, product_id, quantity, price)
         VALUES (?, ?, ?, ?)`,
        [orderId, item.product_id, item.quantity, item.price]
      );
    }

    await connection.commit();
    
    res.status(201).json({
      success: true,
      data: {
        id: orderId,
        order_number: orderNumber,
        total_price: totalPrice,
        status: 'placed',
        created_at: new Date()
      },
      message: 'Заказ успешно создан'
    });
    
  } catch (error) {
    await connection.rollback();
    console.error('Ошибка создания заказа:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Ошибка создания заказа'
    });
  } finally {
    connection.release();
  }
});

// Получить заказы
app.get('/api/orders', async (req, res) => {
  try {
    const { limit = 20, offset = 0, status } = req.query;
    
    let query = `
      SELECT o.*, 
             COUNT(oi.id) as items_count
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
    `;
    const params = [];
    
    if (status) {
      query += ' WHERE o.status = ?';
      params.push(status);
    }
    
    query += ` 
      GROUP BY o.id
      ORDER BY o.created_at DESC 
      LIMIT ? OFFSET ?
    `;
    params.push(parseInt(limit), parseInt(offset));
    
    const [rows] = await pool.execute(query, params);
    
    res.json({
      success: true,
      data: rows,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: rows.length
      }
    });
  } catch (error) {
    console.error('Ошибка получения заказов:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения заказов'
    });
  }
});

// Получить детали заказа
app.get('/api/orders/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Получение основной информации о заказе
    const [orderRows] = await pool.execute(
      'SELECT * FROM orders WHERE id = ?',
      [id]
    );
    
    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Заказ не найден'
      });
    }
    
    // Получение позиций заказа
    const [itemRows] = await pool.execute(
      `SELECT oi.*, p.name as product_name, p.description as product_description
       FROM order_items oi
       LEFT JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = ?`,
      [id]
    );
    
    const order = orderRows[0];
    order.items = itemRows;
    
    res.json({
      success: true,
      data: order
    });
    
  } catch (error) {
    console.error('Ошибка получения деталей заказа:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка получения деталей заказа'
    });
  }
});

// Обработка несуществующих маршрутов
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Маршрут не найден'
  });
});

// Обработка ошибок
app.use((error, req, res, next) => {
  console.error('Внутренняя ошибка сервера:', error);
  res.status(500).json({
    success: false,
    message: 'Внутренняя ошибка сервера'
  });
});

// Запуск сервера
async function startServer() {
  await checkDatabaseConnection();
  
  app.listen(PORT, () => {
    console.log(`🚀 Coffee App API запущен на порту ${PORT}`);
    console.log(`📱 Документация API: http://localhost:${PORT}`);
    console.log(`🗄️  База данных: ${process.env.DB_NAME || 'coffee_app'}`);
  });
}

startServer().catch(error => {
  console.error('❌ Ошибка запуска сервера:', error);
  process.exit(1);
}); 