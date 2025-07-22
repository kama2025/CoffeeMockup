const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Тестовые данные (вместо базы данных)
const categories = [
  { 
    id: 1, 
    name: 'Кофе', 
    icon: '☕',
    display_order: 1,
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  { 
    id: 2, 
    name: 'Чай', 
    icon: '🍃',
    display_order: 2,
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  { 
    id: 3, 
    name: 'Десерты', 
    icon: '🍰',
    display_order: 3,
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  { 
    id: 4, 
    name: 'Выпечка', 
    icon: '🥐',
    display_order: 4,
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  }
];

const products = [
  {
    id: 1,
    name: 'Эспрессо',
    price: 120.0,
    description: 'Классический итальянский эспрессо',
    category_id: 1,
    image_url: null,
    available: true,
    featured: true,
    category_name: 'Кофе',
    category_icon: '☕',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  {
    id: 2,
    name: 'Капучино',
    price: 180.0,
    description: 'Эспрессо с молочной пенкой',
    category_id: 1,
    image_url: null,
    available: true,
    featured: true,
    category_name: 'Кофе',
    category_icon: '☕',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  {
    id: 3,
    name: 'Латте',
    price: 200.0,
    description: 'Мягкий кофе с молоком',
    category_id: 1,
    image_url: null,
    available: true,
    featured: false,
    category_name: 'Кофе',
    category_icon: '☕',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  {
    id: 4,
    name: 'Американо',
    price: 150.0,
    description: 'Эспрессо с горячей водой',
    category_id: 1,
    image_url: null,
    available: true,
    featured: false,
    category_name: 'Кофе',
    category_icon: '☕',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  {
    id: 5,
    name: 'Зеленый чай',
    price: 100.0,
    description: 'Классический зеленый чай',
    category_id: 2,
    image_url: null,
    available: true,
    featured: false,
    category_name: 'Чай',
    category_icon: '🍃',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  {
    id: 6,
    name: 'Чизкейк',
    price: 250.0,
    description: 'Нежный чизкейк с ягодами',
    category_id: 3,
    image_url: null,
    available: true,
    featured: true,
    category_name: 'Десерты',
    category_icon: '🍰',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  },
  {
    id: 7,
    name: 'Круассан',
    price: 80.0,
    description: 'Французский круассан',
    category_id: 4,
    image_url: null,
    available: true,
    featured: false,
    category_name: 'Выпечка',
    category_icon: '🥐',
    created_at: '2024-01-01T00:00:00.000Z',
    updated_at: '2024-01-01T00:00:00.000Z'
  }
];

let orders = [];
let orderIdCounter = 1;

// API Routes

// Получить все категории
app.get('/api/categories', (req, res) => {
  console.log('📂 Запрос категорий');
  res.json({
    success: true,
    data: categories
  });
});

// Получить все товары
app.get('/api/products', (req, res) => {
  console.log('🛍️ Запрос всех товаров');
  let filteredProducts = [...products];
  
  // Фильтрация по категории
  if (req.query.category) {
    const categoryId = parseInt(req.query.category);
    filteredProducts = filteredProducts.filter(p => p.category_id === categoryId);
  }
  
  // Поиск по названию
  if (req.query.search) {
    const searchTerm = req.query.search.toLowerCase();
    filteredProducts = filteredProducts.filter(p => 
      p.name.toLowerCase().includes(searchTerm) || 
      p.description.toLowerCase().includes(searchTerm)
    );
  }
  
  res.json({
    success: true,
    data: filteredProducts
  });
});

// Получить товары по категории
app.get('/api/products/category/:categoryId', (req, res) => {
  const categoryId = parseInt(req.params.categoryId);
  console.log(`🏷️ Запрос товаров категории ${categoryId}`);
  
  const categoryProducts = products.filter(p => p.category_id === categoryId);
  
  res.json({
    success: true,
    data: categoryProducts
  });
});

// Получить рекомендуемые товары
app.get('/api/products/featured', (req, res) => {
  console.log('⭐ Запрос рекомендуемых товаров');
  const featuredProducts = products.filter(p => p.featured);
  
  res.json({
    success: true,
    data: featuredProducts
  });
});

// Создать заказ
app.post('/api/orders', (req, res) => {
  console.log('📝 Создание заказа:', req.body);
  
  const { items, customerName, customerPhone, notes } = req.body;
  
  if (!items || items.length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Заказ должен содержать товары'
    });
  }
  
  // Вычисляем общую стоимость
  let totalPrice = 0;
  const orderItems = items.map(item => {
    const product = products.find(p => p.id === item.product_id);
    if (!product) {
      throw new Error(`Товар с ID ${item.product_id} не найден`);
    }
    
    const itemTotal = product.price * item.quantity;
    totalPrice += itemTotal;
    
    return {
      productId: item.product_id,
      name: product.name,
      price: product.price,
      quantity: item.quantity,
      total: itemTotal
    };
  });
  
  const order = {
    id: orderIdCounter++,
    orderNumber: `ORD-${Date.now()}`,
    totalPrice: totalPrice,
    status: 'placed',
    customerName: customerName || null,
    customerPhone: customerPhone || null,
    notes: notes || null,
    items: orderItems,
    itemsCount: items.length,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  
  orders.push(order);
  
  res.json({
    success: true,
    data: order
  });
});

// Получить заказы
app.get('/api/orders', (req, res) => {
  console.log('📋 Запрос списка заказов');
  
  res.json({
    success: true,
    data: orders
  });
});

// Получить детали заказа
app.get('/api/orders/:orderId', (req, res) => {
  const orderId = parseInt(req.params.orderId);
  console.log(`🔍 Запрос деталей заказа ${orderId}`);
  
  const order = orders.find(o => o.id === orderId);
  
  if (!order) {
    return res.status(404).json({
      success: false,
      message: 'Заказ не найден'
    });
  }
  
  res.json({
    success: true,
    data: order
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Сервер работает',
    timestamp: new Date().toISOString()
  });
});

// Обработка 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Эндпоинт не найден'
  });
});

// Обработка ошибок
app.use((error, req, res, next) => {
  console.error('Ошибка сервера:', error);
  res.status(500).json({
    success: false,
    message: 'Внутренняя ошибка сервера'
  });
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 Демо-сервер кофейни запущен!');
  console.log(`📡 API доступен по адресу: http://localhost:${PORT}/api`);
  console.log('📋 Доступные endpoints:');
  console.log('   GET  /api/categories - Список категорий');
  console.log('   GET  /api/products - Все товары');
  console.log('   GET  /api/products/featured - Рекомендуемые товары');
  console.log('   GET  /api/products/category/:id - Товары по категории');
  console.log('   POST /api/orders - Создать заказ');
  console.log('   GET  /api/orders - Список заказов');
  console.log('   GET  /api/health - Проверка работы сервера');
  console.log('');
  console.log('✅ Готов принимать запросы от iOS приложения!');
}); 