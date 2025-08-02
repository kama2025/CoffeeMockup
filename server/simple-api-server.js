const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'coffee_app_secret_key_2024';

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
// ВСТРОЕННАЯ БАЗА ДАННЫХ (In-Memory)
// ======================================

const database = {
    users: [
        {
            id: 1,
            email: 'ivan.petrov@example.com',
            password_hash: '$2b$10$rQjX.oqzKF2GJz8F8vVj7O8pQxZvz9p6LZ7j6n5oV6gX9c0q6vXqG', // password: 123456
            name: 'Иван Петров',
            phone: '+7999123456',
            loyalty_points: 150,
            total_orders: 3,
            total_spent: 1580.00,
            is_active: true,
            email_verified: true,
            created_at: '2025-01-15T10:00:00Z',
            updated_at: '2025-01-22T14:30:00Z',
            last_login: '2025-01-22T14:30:00Z'
        },
        {
            id: 2,
            email: 'anna.kofeinya@example.com',
            password_hash: '$2b$10$rQjX.oqzKF2GJz8F8vVj7O8pQxZvz9p6LZ7j6n5oV6gX9c0q6vXqG', // password: 123456
            name: 'Анна Кофейна',
            phone: '+7999123457',
            loyalty_points: 75,
            total_orders: 1,
            total_spent: 540.00,
            is_active: true,
            email_verified: true,
            created_at: '2025-01-18T12:00:00Z',
            updated_at: '2025-01-20T10:45:00Z',
            last_login: '2025-01-21T09:15:00Z'
        }
    ],
    categories: [
        { id: 1, name: 'Кофе', icon: 'cup.and.saucer.fill', displayOrder: 1, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
        { id: 2, name: 'Чай', icon: 'leaf.fill', displayOrder: 2, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
        { id: 3, name: 'Десерты', icon: 'birthday.cake.fill', displayOrder: 3, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
        { id: 4, name: 'Холодные напитки', icon: 'drop.fill', displayOrder: 4, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' },
        { id: 5, name: 'Завтраки', icon: 'sun.max.fill', displayOrder: 5, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z' }
    ],
    products: [
        // Кофе (categoryId = 1)
        { id: 1, categoryId: 1, name: 'Эспрессо', description: 'Классический итальянский эспрессо из отборных зерен арабики', price: 120.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 2, categoryId: 1, name: 'Американо', description: 'Эспрессо с горячей водой для мягкого вкуса', price: 150.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 3, categoryId: 1, name: 'Капучино', description: 'Эспрессо с взбитым молоком и воздушной пенкой', price: 220.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 4, categoryId: 1, name: 'Латте', description: 'Нежный эспрессо с большим количеством молока', price: 250.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 5, categoryId: 1, name: 'Флэт Уайт', description: 'Двойной эспрессо с микропенкой', price: 280.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 6, categoryId: 1, name: 'Мокка', description: 'Кофе с шоколадом и взбитыми сливками', price: 290.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 27, categoryId: 1, name: 'Раф кофе', description: 'Кофе со сливками и ванильным сахаром', price: 270.00, imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=400&h=300&fit=crop', available: true, featured: true, createdAt: '2025-01-31T00:00:00Z', updatedAt: '2025-01-31T00:00:00Z', category_name: 'Кофе', category_icon: 'cup.and.saucer.fill' },
        { id: 28, categoryId: 3, name: 'Тирамису', description: 'Классический итальянский десерт с кофе и маскарпоне', price: 380.00, imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400&h=300&fit=crop', available: true, featured: true, createdAt: '2025-01-31T00:00:00Z', updatedAt: '2025-01-31T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        
        // Чай (categoryId = 2)
        { id: 7, categoryId: 2, name: 'Черный чай', description: 'Классический цейлонский черный чай', price: 100.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Чай', category_icon: 'leaf.fill' },
        { id: 8, categoryId: 2, name: 'Зеленый чай', description: 'Освежающий китайский зеленый чай', price: 120.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Чай', category_icon: 'leaf.fill' },
        { id: 9, categoryId: 2, name: 'Травяной чай', description: 'Ароматный микс полезных трав', price: 140.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Чай', category_icon: 'leaf.fill' },
        { id: 10, categoryId: 2, name: 'Чай с лимоном', description: 'Черный чай с свежим лимоном', price: 130.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Чай', category_icon: 'leaf.fill' },
        { id: 11, categoryId: 2, name: 'Масала чай', description: 'Пряный индийский чай со специями', price: 180.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Чай', category_icon: 'leaf.fill' },
        
        // Десерты (categoryId = 3)
        { id: 12, categoryId: 3, name: 'Круассан классический', description: 'Свежий французский круассан', price: 180.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        { id: 13, categoryId: 3, name: 'Круассан с шоколадом', description: 'Круассан с темным шоколадом', price: 220.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        { id: 14, categoryId: 3, name: 'Чизкейк Нью-Йорк', description: 'Нежный творожный торт в американском стиле', price: 320.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        { id: 15, categoryId: 3, name: 'Маффин черничный', description: 'Домашний кекс со свежей черникой', price: 200.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        { id: 16, categoryId: 3, name: 'Тирамису', description: 'Классический итальянский десерт', price: 350.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        { id: 17, categoryId: 3, name: 'Эклер', description: 'Заварное пирожное с кремом', price: 190.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Десерты', category_icon: 'birthday.cake.fill' },
        
        // Холодные напитки (categoryId = 4)
        { id: 18, categoryId: 4, name: 'Лимонад домашний', description: 'Свежий лимонад собственного приготовления', price: 180.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Холодные напитки', category_icon: 'drop.fill' },
        { id: 19, categoryId: 4, name: 'Айс-кофе', description: 'Холодный кофе со льдом', price: 200.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Холодные напитки', category_icon: 'drop.fill' },
        { id: 20, categoryId: 4, name: 'Фраппе', description: 'Взбитый холодный кофе с молоком', price: 250.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Холодные напитки', category_icon: 'drop.fill' },
        { id: 21, categoryId: 4, name: 'Холодный чай', description: 'Освежающий чай со льдом и мятой', price: 160.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Холодные напитки', category_icon: 'drop.fill' },
        { id: 22, categoryId: 4, name: 'Смузи ягодный', description: 'Микс свежих ягод и йогурта', price: 290.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Холодные напитки', category_icon: 'drop.fill' },
        
        // Завтраки (categoryId = 5)
        { id: 23, categoryId: 5, name: 'Сэндвич с курицей', description: 'Свежий сэндвич с грудкой курицы', price: 320.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Завтраки', category_icon: 'sun.max.fill' },
        { id: 24, categoryId: 5, name: 'Омлет классический', description: 'Пушистый омлет из трех яиц', price: 250.00, imageUrl: null, available: true, featured: false, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Завтраки', category_icon: 'sun.max.fill' },
        { id: 25, categoryId: 5, name: 'Гранола с йогуртом', description: 'Домашняя гранола с греческим йогуртом', price: 280.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Завтраки', category_icon: 'sun.max.fill' },
        { id: 26, categoryId: 5, name: 'Тост с авокадо', description: 'Цельнозерновой хлеб с авокадо', price: 290.00, imageUrl: null, available: true, featured: true, createdAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', category_name: 'Завтраки', category_icon: 'sun.max.fill' }
    ],
    orders: [
        { id: 1, orderNumber: 'ORD-001', totalPrice: 540.00, status: 'completed', customerName: 'Анна Петрова', customerPhone: '+7999123456', notes: 'Без сахара', itemsCount: 2, createdAt: '2025-01-20T10:30:00Z', updatedAt: '2025-01-20T10:45:00Z' },
        { id: 2, orderNumber: 'ORD-002', totalPrice: 320.00, status: 'preparing', customerName: 'Иван Смирнов', customerPhone: '+7999123457', notes: null, itemsCount: 1, createdAt: '2025-01-20T11:15:00Z', updatedAt: '2025-01-20T11:15:00Z' },
        { id: 3, orderNumber: 'ORD-003', totalPrice: 720.00, status: 'ready', customerName: 'Мария Кофеина', customerPhone: '+7999123458', notes: 'На вынос', itemsCount: 3, createdAt: '2025-01-20T12:00:00Z', updatedAt: '2025-01-20T12:10:00Z' }
    ],
    orderItems: [
        // Заказ 1
        { id: 1, orderId: 1, productId: 3, quantity: 1, price: 220.00, productName: 'Капучино', productDescription: 'Эспрессо с взбитым молоком и воздушной пенкой', createdAt: '2025-01-20T10:30:00Z' },
        { id: 2, orderId: 1, productId: 14, quantity: 1, price: 320.00, productName: 'Чизкейк Нью-Йорк', productDescription: 'Нежный творожный торт в американском стиле', createdAt: '2025-01-20T10:30:00Z' },
        
        // Заказ 2
        { id: 3, orderId: 2, productId: 23, quantity: 1, price: 320.00, productName: 'Сэндвич с курицей', productDescription: 'Свежий сэндвич с грудкой курицы', createdAt: '2025-01-20T11:15:00Z' },
        
        // Заказ 3
        { id: 4, orderId: 3, productId: 4, quantity: 2, price: 250.00, productName: 'Латте', productDescription: 'Нежный эспрессо с большим количеством молока', createdAt: '2025-01-20T12:00:00Z' },
        { id: 5, orderId: 3, productId: 13, quantity: 1, price: 220.00, productName: 'Круассан с шоколадом', productDescription: 'Круассан с темным шоколадом', createdAt: '2025-01-20T12:00:00Z' }
    ]
};

let nextOrderId = 4;
let nextOrderItemId = 6;
let nextUserId = 3;

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
// MIDDLEWARE АУТЕНТИФИКАЦИИ
// ======================================

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json(createErrorResponse('Токен доступа не предоставлен'));
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json(createErrorResponse('Недействительный токен'));
        }
        req.user = user;
        next();
    });
}

// Опциональная аутентификация (для гостевых заказов)
function optionalAuth(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
        jwt.verify(token, JWT_SECRET, (err, user) => {
            if (!err) {
                req.user = user;
            }
        });
    }
    next();
}

// ======================================
// ПОЛЬЗОВАТЕЛИ
// ======================================

// Регистрация
app.post('/api/auth/register', async (req, res) => {
    try {
        console.log('👤 Регистрация пользователя');
        
        const { email, password, name, phone } = req.body;

        if (!email || !password || !name) {
            return res.status(400).json(createErrorResponse('Email, пароль и имя обязательны'));
        }

        // Проверка на существование пользователя
        const existingUser = database.users.find(u => u.email === email);
        if (existingUser) {
            return res.status(400).json(createErrorResponse('Пользователь с таким email уже существует'));
        }

        // Хеширование пароля
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);

        // Создание пользователя
        const newUser = {
            id: nextUserId++,
            email,
            password_hash,
            name,
            phone: phone || null,
            loyalty_points: 0,
            total_orders: 0,
            total_spent: 0.00,
            is_active: true,
            email_verified: false,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            last_login: null
        };

        database.users.push(newUser);

        // Создание JWT токена
        const token = jwt.sign(
            { userId: newUser.id, email: newUser.email },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        // Ответ без пароля
        const { password_hash: _, ...userResponse } = newUser;

        console.log(`✅ Пользователь ${email} зарегистрирован`);
        res.status(201).json(createSuccessResponse({
            user: userResponse,
            token
        }, 'Регистрация успешна'));

    } catch (error) {
        console.error('Ошибка регистрации:', error);
        res.status(500).json(createErrorResponse('Ошибка регистрации'));
    }
});

// Вход
app.post('/api/auth/login', async (req, res) => {
    try {
        console.log('🔐 Вход пользователя');
        
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json(createErrorResponse('Email и пароль обязательны'));
        }

        // Поиск пользователя
        const user = database.users.find(u => u.email === email && u.is_active);
        if (!user) {
            return res.status(401).json(createErrorResponse('Неверный email или пароль'));
        }

        // Проверка пароля
        const isValidPassword = await bcrypt.compare(password, user.password_hash);
        if (!isValidPassword) {
            return res.status(401).json(createErrorResponse('Неверный email или пароль'));
        }

        // Обновление времени входа
        user.last_login = new Date().toISOString();
        user.updated_at = new Date().toISOString();

        // Создание JWT токена
        const token = jwt.sign(
            { userId: user.id, email: user.email },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        // Ответ без пароля
        const { password_hash: _, ...userResponse } = user;

        console.log(`✅ Пользователь ${email} вошел в систему`);
        res.json(createSuccessResponse({
            user: userResponse,
            token
        }, 'Вход выполнен успешно'));

    } catch (error) {
        console.error('Ошибка входа:', error);
        res.status(500).json(createErrorResponse('Ошибка входа'));
    }
});

// Профиль пользователя
app.get('/api/auth/profile', authenticateToken, (req, res) => {
    console.log('👤 Запрос профиля пользователя');
    
    const user = database.users.find(u => u.id === req.user.userId);
    if (!user) {
        return res.status(404).json(createErrorResponse('Пользователь не найден'));
    }

    const { password_hash: _, ...userResponse } = user;
    res.json(createSuccessResponse(userResponse));
});

// Обновление профиля
app.put('/api/auth/profile', authenticateToken, (req, res) => {
    try {
        console.log('📝 Обновление профиля пользователя');
        
        const { name, phone, date_of_birth } = req.body;
        
        const userIndex = database.users.findIndex(u => u.id === req.user.userId);
        if (userIndex === -1) {
            return res.status(404).json(createErrorResponse('Пользователь не найден'));
        }

        // Обновление данных
        if (name) database.users[userIndex].name = name;
        if (phone) database.users[userIndex].phone = phone;
        if (date_of_birth) database.users[userIndex].date_of_birth = date_of_birth;
        
        database.users[userIndex].updated_at = new Date().toISOString();

        const { password_hash: _, ...userResponse } = database.users[userIndex];

        console.log(`✅ Профиль пользователя ${userResponse.email} обновлен`);
        res.json(createSuccessResponse(userResponse, 'Профиль обновлен'));

    } catch (error) {
        console.error('Ошибка обновления профиля:', error);
        res.status(500).json(createErrorResponse('Ошибка обновления профиля'));
    }
});

// ======================================
// КАТЕГОРИИ
// ======================================

app.get('/api/categories', (req, res) => {
    console.log('📂 Запрос категорий');
    res.json(createSuccessResponse(database.categories));
});

// ======================================
// ТОВАРЫ
// ======================================

app.get('/api/products', (req, res) => {
    console.log('🛍️ Запрос товаров');
    
    const { category_id, search, featured, limit = 50, offset = 0 } = req.query;
    
    let products = database.products.filter(p => p.available);
    
    // Фильтрация по категории
    if (category_id) {
        products = products.filter(p => p.categoryId === parseInt(category_id));
    }
    
    // Поиск
    if (search) {
        const searchLower = search.toLowerCase();
        products = products.filter(p => 
            p.name.toLowerCase().includes(searchLower) ||
            p.description.toLowerCase().includes(searchLower)
        );
    }
    
    // Рекомендуемые
    if (featured === 'true') {
        products = products.filter(p => p.featured);
    }
    
    // Пагинация
    const total = products.length;
    const limitNum = parseInt(limit);
    const offsetNum = parseInt(offset);
    
    products = products.slice(offsetNum, offsetNum + limitNum);
    
    const pagination = {
        limit: limitNum,
        offset: offsetNum,
        total
    };
    
    res.json(createSuccessResponse(products, null, pagination));
});

app.get('/api/products/category/:categoryId', (req, res) => {
    const categoryId = parseInt(req.params.categoryId);
    console.log(`🛍️ Запрос товаров категории ${categoryId}`);
    
    const products = database.products.filter(p => 
        p.categoryId === categoryId && p.available
    );
    
    res.json(createSuccessResponse(products));
});

app.get('/api/products/featured', (req, res) => {
    console.log('⭐ Запрос рекомендуемых товаров');
    
    const products = database.products.filter(p => p.featured && p.available);
    
    res.json(createSuccessResponse(products));
});

// ======================================
// ЗАКАЗЫ
// ======================================

app.post('/api/orders', optionalAuth, (req, res) => {
    try {
        console.log('📝 Создание заказа');
        
        const { items, customerName, customerPhone, notes } = req.body;

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json(createErrorResponse('Корзина пуста'));
        }

        // Создаем номер заказа
        const orderNumber = `ORD-${Date.now()}`;
        
        // Получаем информацию о товарах
        const productIds = items.map(item => item.productId);
        const products = database.products.filter(p => productIds.includes(p.id));

        // Проверяем доступность товаров
        const unavailableProducts = products.filter(p => !p.available);
        if (unavailableProducts.length > 0) {
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
        const newOrder = {
            id: nextOrderId++,
            orderNumber: orderNumber,
            totalPrice: totalPrice,
            status: 'placed',
            customerName: customerName,
            customerPhone: customerPhone,
            notes: notes,
            itemsCount: items.length,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        database.orders.push(newOrder);

        // Добавляем позиции заказа
        const dbOrderItems = orderItems.map(item => ({
            id: nextOrderItemId++,
            orderId: newOrder.id,
            productId: item.productId,
            quantity: item.quantity,
            price: item.price,
            productName: item.productName,
            productDescription: item.productDescription,
            createdAt: new Date().toISOString()
        }));

        database.orderItems.push(...dbOrderItems);

        // Формируем ответ
        const orderResponse = {
            id: newOrder.id,
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
            createdAt: newOrder.createdAt,
            updatedAt: newOrder.updatedAt
        };

        console.log(`✅ Заказ ${orderNumber} создан на ${totalPrice}₽`);
        res.status(201).json(createSuccessResponse(orderResponse, 'Заказ успешно создан'));

    } catch (error) {
        console.error('Ошибка создания заказа:', error);
        res.status(500).json(createErrorResponse('Ошибка создания заказа'));
    }
});

app.get('/api/orders', (req, res) => {
    console.log('📋 Запрос заказов');
    
    const { status, limit = 20, offset = 0 } = req.query;
    
    let orders = database.orders;
    
    // Фильтрация по статусу
    if (status) {
        orders = orders.filter(o => o.status === status);
    }
    
    // Сортировка по дате
    orders = orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Пагинация
    const total = orders.length;
    const limitNum = parseInt(limit);
    const offsetNum = parseInt(offset);
    
    orders = orders.slice(offsetNum, offsetNum + limitNum);
    
    const pagination = {
        limit: limitNum,
        offset: offsetNum,
        total
    };
    
    res.json(createSuccessResponse(orders, null, pagination));
});

app.get('/api/orders/:orderId', (req, res) => {
    const orderId = parseInt(req.params.orderId);
    console.log(`📋 Запрос заказа ${orderId}`);
    
    const order = database.orders.find(o => o.id === orderId);
    
    if (!order) {
        return res.status(404).json(createErrorResponse('Заказ не найден'));
    }

    // Получаем позиции заказа
    const orderItems = database.orderItems.filter(oi => oi.orderId === orderId);
    
    const orderWithItems = {
        ...order,
        items: orderItems
    };
    
    res.json(createSuccessResponse(orderWithItems));
});

// ======================================
// ЗДОРОВЬЕ СИСТЕМЫ
// ======================================

app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        database: 'in-memory',
        server_time: new Date().toISOString(),
        version: '1.0.0',
        data_stats: {
            categories: database.categories.length,
            products: database.products.length,
            orders: database.orders.length,
            orderItems: database.orderItems.length
        }
    });
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

app.listen(PORT, '0.0.0.0', () => {
    console.log('🚀 API Сервер кофейни запущен! (In-Memory Database)');
    console.log('📡 API доступен по адресу:', `http://localhost:${PORT}/api`);
    console.log('🌐 Внешний доступ:', `http://192.168.31.118:${PORT}/api`);
    console.log('🗄️  База данных: In-Memory (совместимый с MySQL API)');
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
    console.log('📈 Статистика данных:');
    console.log(`   📂 Категорий: ${database.categories.length}`);
    console.log(`   🛍️  Товаров: ${database.products.length}`);
    console.log(`   📋 Заказов: ${database.orders.length}`);
    console.log('');
    console.log('✅ Готов принимать запросы от iOS приложения!');
});

module.exports = app; 