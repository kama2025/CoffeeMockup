const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

// Конфигурация подключения к MySQL
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true
};

const DB_NAME = 'coffeeshop_db';
const SCHEMA_FILE = path.join(__dirname, 'schema-mysql.sql');

async function initializeDatabase() {
    console.log('🗄️  Инициализация MySQL базы данных для кофейни...');
    console.log(`📡 Подключение: ${dbConfig.user}@${dbConfig.host}:${dbConfig.port}`);
    
    let connection;
    
    try {
        // Подключение к MySQL серверу
        connection = await mysql.createConnection(dbConfig);
        console.log('✅ Подключение к MySQL установлено');
        
        // Проверка существования базы данных
        const [databases] = await connection.execute(`SHOW DATABASES LIKE '${DB_NAME}'`);
        if (databases.length > 0) {
            console.log(`🗑️  База данных ${DB_NAME} существует, будет пересоздана`);
        }
        
        // Чтение и выполнение схемы
        if (!fs.existsSync(SCHEMA_FILE)) {
            throw new Error(`Файл схемы не найден: ${SCHEMA_FILE}`);
        }
        
        const schema = fs.readFileSync(SCHEMA_FILE, 'utf8');
        console.log('📋 Выполнение SQL схемы...');
        
        await connection.query(schema);
        console.log('✅ База данных и таблицы созданы');
        
        // Переключение на созданную базу данных
        await connection.execute(`USE ${DB_NAME}`);
        
        // Проверка созданных таблиц
        const [tables] = await connection.execute('SHOW TABLES');
        console.log('📊 Созданные таблицы:', tables.map(t => Object.values(t)[0]).join(', '));
        
        // Проверка количества данных
        const [categoriesCount] = await connection.execute('SELECT COUNT(*) as count FROM categories');
        const [productsCount] = await connection.execute('SELECT COUNT(*) as count FROM products');
        const [ordersCount] = await connection.execute('SELECT COUNT(*) as count FROM orders');
        const [orderItemsCount] = await connection.execute('SELECT COUNT(*) as count FROM order_items');
        
        console.log('\n📈 Статистика данных:');
        console.log(`   📂 Категорий: ${categoriesCount[0].count}`);
        console.log(`   🛍️  Товаров: ${productsCount[0].count}`);
        console.log(`   📋 Заказов: ${ordersCount[0].count}`);
        console.log(`   📦 Позиций заказов: ${orderItemsCount[0].count}`);
        
        // Проверка представлений
        const [views] = await connection.execute("SHOW FULL TABLES WHERE table_type = 'VIEW'");
        console.log(`   👁️  Представлений: ${views.length}`);
        
        console.log('\n🎉 База данных успешно инициализирована!');
        printConnectionInfo();
        
    } catch (error) {
        console.error('\n❌ Ошибка инициализации:', error.message);
        
        if (error.code === 'ECONNREFUSED') {
            console.error('\n💡 Возможные решения:');
            console.error('   1. Убедитесь, что MySQL сервер запущен');
            console.error('   2. Для macOS: brew services start mysql');
            console.error('   3. Для Linux: sudo systemctl start mysql');
            console.error('   4. Проверьте параметры подключения');
        } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
            console.error('\n💡 Проблема с доступом:');
            console.error('   1. Проверьте имя пользователя и пароль');
            console.error('   2. Убедитесь, что пользователь имеет права CREATE DATABASE');
        }
        
        throw error;
    } finally {
        if (connection) {
            await connection.end();
        }
    }
}

async function testConnection() {
    console.log('🔍 Проверка подключения к MySQL...');
    
    try {
        const connection = await mysql.createConnection(dbConfig);
        const [result] = await connection.execute('SELECT VERSION() as version, NOW() as time');
        
        console.log('✅ MySQL работает корректно');
        console.log(`   📌 Версия: ${result[0].version}`);
        console.log(`   🕒 Время сервера: ${result[0].time}`);
        
        await connection.end();
        return true;
    } catch (error) {
        console.error('❌ Ошибка подключения:', error.message);
        return false;
    }
}

async function showDatabaseInfo() {
    try {
        const connection = await mysql.createConnection({...dbConfig, database: DB_NAME});
        
        console.log(`\n📊 Информация о базе данных ${DB_NAME}:`);
        
        // Список таблиц
        const [tables] = await connection.execute('SHOW TABLES');
        console.log(`\n📋 Таблицы (${tables.length}):`);
        tables.forEach(table => {
            console.log(`   • ${Object.values(table)[0]}`);
        });
        
        // Статистика данных
        const stats = await Promise.all([
            connection.execute('SELECT COUNT(*) as count FROM categories'),
            connection.execute('SELECT COUNT(*) as count FROM products WHERE available = TRUE'),
            connection.execute('SELECT COUNT(*) as count FROM products WHERE featured = TRUE'),
            connection.execute('SELECT COUNT(*) as count FROM orders'),
            connection.execute('SELECT COUNT(*) as count FROM order_items')
        ]);
        
        console.log('\n📈 Статистика:');
        console.log(`   📂 Категорий: ${stats[0][0][0].count}`);
        console.log(`   🛍️  Доступных товаров: ${stats[1][0][0].count}`);
        console.log(`   ⭐ Рекомендуемых товаров: ${stats[2][0][0].count}`);
        console.log(`   📋 Заказов: ${stats[3][0][0].count}`);
        console.log(`   📦 Позиций заказов: ${stats[4][0][0].count}`);
        
        // Топ товары
        const [topProducts] = await connection.execute(`
            SELECT p.name, SUM(oi.quantity) as total_ordered
            FROM products p
            JOIN order_items oi ON p.id = oi.product_id
            GROUP BY p.id, p.name
            ORDER BY total_ordered DESC
            LIMIT 5
        `);
        
        if (topProducts.length > 0) {
            console.log('\n🏆 Топ товары:');
            topProducts.forEach((product, index) => {
                console.log(`   ${index + 1}. ${product.name} (${product.total_ordered} заказов)`);
            });
        }
        
        await connection.end();
    } catch (error) {
        console.error('❌ Ошибка получения информации:', error.message);
    }
}

function printConnectionInfo() {
    console.log('\n' + '='.repeat(60));
    console.log('🔗 ИНФОРМАЦИЯ ДЛЯ ПОДКЛЮЧЕНИЯ');
    console.log('='.repeat(60));
    console.log(`📡 Host: ${dbConfig.host}:${dbConfig.port}`);
    console.log(`🗄️  Database: ${DB_NAME}`);
    console.log(`👤 User: ${dbConfig.user}`);
    console.log('\n📱 Для iOS приложения:');
    console.log(`   baseURL: "http://${dbConfig.host}:3000/api"`);
    console.log('\n🚀 Следующие шаги:');
    console.log('   1. npm start - запустить сервер API');
    console.log('   2. Проверить endpoints через Postman/curl');
    console.log('   3. Подключить iOS приложение');
    console.log('='.repeat(60));
}

// Главная функция
async function main() {
    const args = process.argv.slice(2);
    
    try {
        if (args.includes('--test')) {
            const success = await testConnection();
            process.exit(success ? 0 : 1);
        } else if (args.includes('--info')) {
            await showDatabaseInfo();
        } else {
            await initializeDatabase();
        }
    } catch (error) {
        console.error('\n💥 Критическая ошибка:', error.message);
        process.exit(1);
    }
}

// Запуск только если файл выполняется напрямую
if (require.main === module) {
    main();
}

module.exports = {
    initializeDatabase,
    testConnection,
    showDatabaseInfo
}; 