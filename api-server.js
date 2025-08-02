const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// ======================================
// КОНФИГУРАЦИЯ MySQL
// ======================================

const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: 'coffeeshop_db',
    connectionLimit: 10,
    acquireTimeout: 60000,
    timeout: 60000,
    charset: 'utf8mb4'
};

// Создаем пул соединений
const pool = mysql.createPool(dbConfig);

// ======================================
// MIDDLEWARE
// ======================================

app.use(helmet());
app.use(cors({
    origin: ['http://localhost:3000', 'http://192.168.31.118:3000'],
    credentials: true
}));
app.use(express.json());
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 минут
    max: 100,
    message: { 
        success: false, 
        message: 'Слишком много запросов. Попробуйте позже.' 
    }
});
app.use('/api/', limiter);

// ======================================
// УТИЛИТЫ
// ======================================

function createSuccessResponse(data, message = null, pagination = null) {
    return {
        success: true,
        data,
        message,
        pagination
    };
}

function createErrorResponse(message, error = null) {
    return {
        success: false,
        data: null,
        message,
        error
    };
}

// ======================================
// КАТЕГОРИИ
// ======================================

app.get('/api/categories', async (req, res) => {
    try {
        console.log('📂 Запрос категорий');
        
        const [categories] = await pool.execute(`
            SELECT 
                id,
                name,
                icon,
                display_order as displayOrder,
                created_at as createdAt,
                updated_at as updatedAt
            FROM categories 
            WHERE is_active = TRUE 
            ORDER BY display_order
        `);

        res.json(createSuccessResponse(categories));
    } catch (error) {
        console.error('Ошибка получения категорий:', error);
        res.status(500).json(createErrorResponse('Ошибка получения категорий'));
    }
});

// ======================================
// ТОВАРЫ
// ======================================

app.get('/api/products', async (req, res) => {
    try {
        console.log('🛍️ Запрос товаров');
        
        const { 
            category_id, 
            search, 
            featured,
            limit = 50, 
            offset = 0 
        } = req.query;

        let query = `
            SELECT 
                p.id,
                p.category_id as categoryId,
                p.name,
                p.description,
                p.price,
                p.image_url as imageUrl,
                p.available,
                p.featured,
                p.created_at as createdAt,
                p.updated_at as updatedAt,
                c.name as category_name,
                c.icon as category_icon
            FROM products p
            JOIN categories c ON p.category_id = c.id
            WHERE p.available = TRUE
        `;
        
        const params = [];

        if (category_id) {
            query += ' AND p.category_id = ?';
            params.push(parseInt(category_id));
        }

        if (search) {
            query += ' AND (p.name LIKE ? OR p.description LIKE ?)';
            params.push(`%${search}%`, `%${search}%`);
        }

        if (featured === 'true') {
            query += ' AND p.featured = TRUE';
        }

        query += ' ORDER BY c.display_order, p.display_order LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const [products] = await pool.execute(query, params);

        // Подсчет общего количества
        let countQuery = `
            SELECT COUNT(*) as total
            FROM products p
            WHERE p.available = TRUE
        `;
        
        const countParams = [];
        
        if (category_id) {
            countQuery += ' AND p.category_id = ?';
            countParams.push(parseInt(category_id));
        }

        if (search) {
            countQuery += ' AND (p.name LIKE ? OR p.description LIKE ?)';
            countParams.push(`%${search}%`, `%${search}%`);
        }

        if (featured === 'true') {
            countQuery += ' AND p.featured = TRUE';
        }

        const [countResult] = await pool.execute(countQuery, countParams);
        const total = countResult[0].total;

        const pagination = {
            limit: parseInt(limit),
            offset: parseInt(offset),
            total
        };

        res.json(createSuccessResponse(products, null, pagination));
    } catch (error) {
        console.error('Ошибка получения товаров:', error);
        res.status(500).json(createErrorResponse('Ошибка получения товаров'));
    }
});

app.get('/api/products/category/:categoryId', async (req, res) => {
    try {
        const categoryId = parseInt(req.params.categoryId);
        console.log(`🛍️ Запрос товаров категории ${categoryId}`);
        
        const [products] = await pool.execute(`
            SELECT 
                p.id,
                p.category_id as categoryId,
                p.name,
                p.description,
                p.price,
                p.image_url as imageUrl,
                p.available,
                p.featured,
                p.created_at as createdAt,
                p.updated_at as updatedAt,
                c.name as category_name,
                c.icon as category_icon
            FROM products p
            JOIN categories c ON p.category_id = c.id
            WHERE p.category_id = ? AND p.available = TRUE
            ORDER BY p.display_order
        `, [categoryId]);

        res.json(createSuccessResponse(products));
    } catch (error) {
        console.error('Ошибка получения товаров категории:', error);
        res.status(500).json(createErrorResponse('Ошибка получения товаров категории'));
    }
});

app.get('/api/products/featured', async (req, res) => {
    try {
        console.log('⭐ Запрос рекомендуемых товаров');
        
        const [products] = await pool.execute(`
            SELECT 
                p.id,
                p.category_id as categoryId,
                p.name,
                p.description,
                p.price,
                p.image_url as imageUrl,
                p.available,
                p.featured,
                p.created_at as createdAt,
                p.updated_at as updatedAt,
                c.name as category_name,
                c.icon as category_icon
            FROM products p
            JOIN categories c ON p.category_id = c.id
            WHERE p.featured = TRUE AND p.available = TRUE
            ORDER BY c.display_order, p.display_order
        `);

        res.json(createSuccessResponse(products));
    } catch (error) {
        console.error('Ошибка получения рекомендуемых товаров:', error);
        res.status(500).json(createErrorResponse('Ошибка получения рекомендуемых товаров'));
    }
});

// ======================================
// ЗАКАЗЫ
// ======================================

app.post('/api/orders', async (req, res) => {
    const connection = await pool.getConnection();
    
    try {
        console.log('📝 Создание заказа');
        
        const { items, customerName, customerPhone, notes } = req.body;

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json(createErrorResponse('Корзина пуста'));
        }

        await connection.beginTransaction();

        // Создаем номер заказа
        const orderNumber = `ORD-${Date.now()}`;
        
        // Получаем информацию о товарах
        const productIds = items.map(item => item.productId);
        const placeholders = productIds.map(() => '?').join(',');
        
        const [products] = await connection.execute(
            `SELECT id, name, description, price, available FROM products WHERE id IN (${placeholders})`,
            productIds
        );

        // Проверяем доступность товаров
        const unavailableProducts = products.filter(p => !p.available);
        if (unavailableProducts.length > 0) {
            await connection.rollback();
            return res.status(400).json(createErrorResponse(
                'Некоторые товары недоступны',
                unavailableProducts.map(p => ({ id: p.id, name: p.name }))
            ));
        }

        // Вычисляем общую стоимость
        let totalPrice = 0;
        const orderItems = items.map(item => {
            const product = products.find(p => p.id === item.productId);
            if (!product) {
                throw new Error(`Товар с ID ${item.productId} не найден`);
            }
            
            const itemTotal = product.price * item.quantity;
            totalPrice += itemTotal;
            
            return {
                productId: item.productId,
                quantity: item.quantity,
                price: product.price,
                productName: product.name,
                productDescription: product.description
            };
        });

        // Создаем заказ
        const [orderResult] = await connection.execute(`
            INSERT INTO orders (order_number, total_price, customer_name, customer_phone, notes, items_count)
            VALUES (?, ?, ?, ?, ?, ?)
        `, [orderNumber, totalPrice, customerName, customerPhone, notes, items.length]);

        const orderId = orderResult.insertId;

        // Добавляем позиции заказа
        for (const item of orderItems) {
            await connection.execute(`
                INSERT INTO order_items (order_id, product_id, quantity, price, product_name, product_description)
                VALUES (?, ?, ?, ?, ?, ?)
            `, [orderId, item.productId, item.quantity, item.price, item.productName, item.productDescription]);
        }

        await connection.commit();

        // Формируем ответ
        const orderResponse = {
            id: orderId,
            orderNumber: orderNumber,
            totalPrice: totalPrice,
            status: 'placed',
            customerName: customerName,
            customerPhone: customerPhone,
            notes: notes,
            items: orderItems.map(item => ({
                productId: item.productId,
                name: item.productName,
                price: item.price,
                quantity: item.quantity,
                total: item.price * item.quantity
            })),
            itemsCount: items.length,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        console.log(`✅ Заказ ${orderNumber} создан на ${totalPrice}₽`);
        res.status(201).json(createSuccessResponse(orderResponse, 'Заказ успешно создан'));

    } catch (error) {
        await connection.rollback();
        console.error('Ошибка создания заказа:', error);
        res.status(500).json(createErrorResponse('Ошибка создания заказа'));
    } finally {
        connection.release();
    }
});

app.get('/api/orders', async (req, res) => {
    try {
        console.log('📋 Запрос заказов');
        
        const { 
            status, 
            limit = 20, 
            offset = 0 
        } = req.query;

        let query = `
            SELECT 
                id,
                order_number as orderNumber,
                total_price as totalPrice,
                status,
                customer_name as customerName,
                customer_phone as customerPhone,
                notes,
                items_count as itemsCount,
                created_at as createdAt,
                updated_at as updatedAt
            FROM orders
        `;
        
        const params = [];

        if (status) {
            query += ' WHERE status = ?';
            params.push(status);
        }

        query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const [orders] = await pool.execute(query, params);

        // Подсчет общего количества
        let countQuery = 'SELECT COUNT(*) as total FROM orders';
        const countParams = [];
        
        if (status) {
            countQuery += ' WHERE status = ?';
            countParams.push(status);
        }

        const [countResult] = await pool.execute(countQuery, countParams);
        const total = countResult[0].total;

        const pagination = {
            limit: parseInt(limit),
            offset: parseInt(offset),
            total
        };

        res.json(createSuccessResponse(orders, null, pagination));
    } catch (error) {
        console.error('Ошибка получения заказов:', error);
        res.status(500).json(createErrorResponse('Ошибка получения заказов'));
    }
});

app.get('/api/orders/:orderId', async (req, res) => {
    try {
        const orderId = parseInt(req.params.orderId);
        console.log(`📋 Запрос заказа ${orderId}`);
        
        const [orders] = await pool.execute(`
            SELECT 
                id,
                order_number as orderNumber,
                total_price as totalPrice,
                status,
                customer_name as customerName,
                customer_phone as customerPhone,
                notes,
                items_count as itemsCount,
                created_at as createdAt,
                updated_at as updatedAt
            FROM orders 
            WHERE id = ?
        `, [orderId]);

        if (orders.length === 0) {
            return res.status(404).json(createErrorResponse('Заказ не найден'));
        }

        const order = orders[0];

        // Получаем позиции заказа
        const [orderItems] = await pool.execute(`
            SELECT 
                id,
                product_id as productId,
                quantity,
                price,
                product_name as productName,
                product_description as productDescription,
                created_at as createdAt
            FROM order_items 
            WHERE order_id = ?
        `, [orderId]);

        order.items = orderItems;

        res.json(createSuccessResponse(order));
    } catch (error) {
        console.error('Ошибка получения заказа:', error);
        res.status(500).json(createErrorResponse('Ошибка получения заказа'));
    }
});

// ======================================
// ЗДОРОВЬЕ СИСТЕМЫ
// ======================================

app.get('/api/health', async (req, res) => {
    try {
        const [result] = await pool.execute('SELECT 1 as test, NOW() as time');
        
        res.json({
            status: 'OK',
            timestamp: new Date().toISOString(),
            database: 'connected',
            server_time: result[0].time,
            version: '1.0.0'
        });
    } catch (error) {
        res.status(500).json({
            status: 'ERROR',
            timestamp: new Date().toISOString(),
            database: 'disconnected',
            error: error.message
        });
    }
});

// ======================================
// ОБРАБОТКА ОШИБОК
// ======================================

app.use((err, req, res, next) => {
    console.error('Необработанная ошибка:', err);
    res.status(500).json(createErrorResponse('Внутренняя ошибка сервера'));
});

app.use((req, res) => {
    res.status(404).json(createErrorResponse('Эндпоинт не найден'));
});

// ======================================
// ЗАПУСК СЕРВЕРА
// ======================================

async function startServer() {
    try {
        // Проверка подключения к базе данных
        const connection = await pool.getConnection();
        console.log('✅ Подключение к MySQL базе данных установлено');
        connection.release();

        app.listen(PORT, '0.0.0.0', () => {
            console.log('🚀 API Сервер кофейни запущен!');
            console.log('📡 API доступен по адресу:', `http://localhost:${PORT}/api`);
            console.log('🌐 Внешний доступ:', `http://192.168.31.118:${PORT}/api`);
            console.log('🗄️  База данных: MySQL (coffeeshop_db)');
            console.log('');
            console.log('📋 Основные endpoints:');
            console.log('   GET  /api/categories - Категории товаров');
            console.log('   GET  /api/products - Все товары');
            console.log('   GET  /api/products/featured - Рекомендуемые товары');
            console.log('   GET  /api/products/category/:id - Товары категории');
            console.log('   POST /api/orders - Создать заказ');
            console.log('   GET  /api/orders - Список заказов');
            console.log('   GET  /api/orders/:id - Детали заказа');
            console.log('   GET  /api/health - Состояние системы');
            console.log('');
            console.log('✅ Готов принимать запросы от iOS приложения!');
        });
    } catch (error) {
        console.error('❌ Ошибка запуска сервера:', error.message);
        console.error('💡 Проверьте подключение к MySQL базе данных');
        process.exit(1);
    }
}

// Обработка сигналов завершения
process.on('SIGINT', async () => {
    console.log('\n🛑 Получен сигнал завершения, закрываем соединения...');
    await pool.end();
    console.log('✅ Все соединения закрыты');
    process.exit(0);
});

startServer();

module.exports = app; 