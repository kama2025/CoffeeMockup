import SwiftUI

struct AppConfig {
    // Цвета теперь централизованы в ColorTheme
    static var primaryColor: Color = ColorTheme.primary
    static var accentColor: Color = ColorTheme.accent
    static var backgroundColor: Color = ColorTheme.background
    static var textColor: Color = ColorTheme.textPrimary
    
    // Информация о кофейне
    static var cafeName: String = "Кофейня 'Уютный уголок'"
    static var cafeAddress: String = "ул. Пушкина, 15, Москва"
    static var cafePhone: String = "+7 (495) 123-45-67"
    
    // Красиво оформленное меню
    static var menuCategories: [MenuCategory] = [
        MenuCategory(
            name: "☕️ Кофе",
            items: [
                MenuItem(name: "Эспрессо", price: 150, description: "Классический итальянский кофе"),
                MenuItem(name: "Американо", price: 180, description: "Эспрессо с горячей водой"),
                MenuItem(name: "Капучино", price: 220, description: "Эспрессо с молочной пенкой"),
                MenuItem(name: "Латте", price: 250, description: "Нежный кофе с молоком"),
                MenuItem(name: "Раф", price: 280, description: "Сливочный кофе по-русски")
            ]
        ),
        MenuCategory(
            name: "🍰 Десерты",
            items: [
                MenuItem(name: "Чизкейк", price: 320, description: "Нежный творожный торт"),
                MenuItem(name: "Тирамису", price: 350, description: "Итальянский десерт с кофе"),
                MenuItem(name: "Эклер", price: 180, description: "Заварное пирожное с кремом"),
                MenuItem(name: "Макарон", price: 120, description: "Французское миндальное печенье")
            ]
        ),
        MenuCategory(
            name: "🥪 Закуски",
            items: [
                MenuItem(name: "Круассан", price: 200, description: "Свежая французская выпечка"),
                MenuItem(name: "Сэндвич", price: 350, description: "С ветчиной и сыром"),
                MenuItem(name: "Салат", price: 420, description: "Свежий микс с курицей")
            ]
        )
    ]
}

struct MenuCategory: Codable {
    let name: String
    let items: [MenuItem]
}

struct MenuItem: Identifiable, Codable {
    var id = UUID()
    var productId: Int?  // For API mapping
    let name: String
    let price: Int
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case productId
        case name
        case price
        case description
    }

    var formattedPrice: String {
        return "\(price) ₽"
    }
} 