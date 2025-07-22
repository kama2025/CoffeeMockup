import Foundation
import Combine
import UIKit

class ModernCartManager: ObservableObject {
    static let shared = ModernCartManager()
    
    @Published var cartItems: [CartItem] = []
    @Published var orderHistory: [Order] = []
    @Published var isLoading = false
    @Published var lastError: APIError?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadOrderHistory()
    }
    
    // MARK: - Cart Operations
    
    func addToCart(product: Product) {
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.name == product.name }) {
            cartItems[existingIndex].quantity += 1
        } else {
            var menuItem = MenuItem(
                name: product.name,
                price: Int(product.price),
                description: product.description ?? ""
            )
            menuItem.productId = product.id
            let cartItem = CartItem(
                menuItem: menuItem,
                quantity: 1
            )
            cartItems.append(cartItem)
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func addToCart(item: MenuItem) {
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.name == item.name }) {
            cartItems[existingIndex].quantity += 1
        } else {
            var updatedMenuItem = item
            // Try to find matching product by name to get the correct productId
            // This is a fallback for MenuItem objects from Config.swift that don't have productId set
            if updatedMenuItem.productId == nil {
                // For now, we'll generate a simple mapping based on name
                // In a real app, this should be handled more robustly
                let nameToIdMapping: [String: Int] = [
                    "Эспрессо": 1,
                    "Капучино": 2,
                    "Американо": 3,
                    "Латте": 4,
                    "Раф": 5,
                    "Чизкейк": 6,
                    "Тирамису": 7,
                    "Эклер": 8,
                    "Макарон": 9,
                    "Круассан": 10,
                    "Сэндвич": 11,
                    "Салат": 12
                ]
                updatedMenuItem.productId = nameToIdMapping[item.name] ?? 1
            }
            
            let cartItem = CartItem(
                menuItem: updatedMenuItem,
                quantity: 1
            )
            cartItems.append(cartItem)
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func removeFromCart(cartItem: CartItem) {
        cartItems.removeAll { $0.id == cartItem.id }
    }
    
    func updateQuantity(cartItem: CartItem, quantity: Int) {
        if let index = cartItems.firstIndex(where: { $0.id == cartItem.id }) {
            if quantity <= 0 {
                cartItems.remove(at: index)
            } else {
                cartItems[index].quantity = quantity
            }
        }
    }
    
    func clearCart() {
        cartItems.removeAll()
    }
    
    // MARK: - Cart Calculations
    
    var totalPrice: Double {
        cartItems.reduce(0) { $0 + Double($1.totalPrice) }
    }
    
    var formattedTotalPrice: String {
        "\(Int(totalPrice)) ₽"
    }
    
    var totalItems: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }
    
    // MARK: - Order Operations
    
    func placeOrder(
        customerName: String? = nil,
        customerPhone: String? = nil,
        notes: String? = nil,
        completion: @escaping (Result<Order, APIError>) -> Void
    ) {
        guard !cartItems.isEmpty else {
            completion(.failure(.serverError("Корзина пуста")))
            return
        }
        
        isLoading = true
        
        apiService.createOrder(
            items: cartItems,
            customerName: customerName,
            customerPhone: customerPhone,
            notes: notes
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                if case .failure(let error) = completionResult {
                    self?.lastError = error
                    completion(.failure(error))
                }
            },
            receiveValue: { [weak self] order in
                self?.orderHistory.insert(order, at: 0)
                self?.saveOrderHistory()
                self?.clearCart()
                
                // Add success haptic feedback
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                completion(.success(order))
            }
        )
        .store(in: &cancellables)
    }
    
    func loadOrderHistory() {
        // Load from UserDefaults as backup
        if let data = UserDefaults.standard.data(forKey: "orderHistory"),
           let decoded = try? JSONDecoder().decode([Order].self, from: data) {
            orderHistory = decoded
        }
        
        // Fetch from API
        refreshOrderHistory()
    }
    
    func refreshOrderHistory() {
        apiService.fetchOrders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.lastError = error
                    }
                },
                receiveValue: { [weak self] orders in
                    self?.orderHistory = orders
                    self?.saveOrderHistory()
                }
            )
            .store(in: &cancellables)
    }
    
    private func saveOrderHistory() {
        if let encoded = try? JSONEncoder().encode(orderHistory) {
            UserDefaults.standard.set(encoded, forKey: "orderHistory")
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        lastError = nil
    }
}

// MARK: - Data Types

struct CartItem: Identifiable, Codable {
    let id = UUID()
    let menuItem: MenuItem
    var quantity: Int
    
    var totalPrice: Int {
        menuItem.price * quantity
    }
    
    var formattedTotalPrice: String {
        "\(totalPrice) ₽"
    }
}

struct Order: Identifiable, Codable {
    let id: UUID
    let number: Int
    let items: [CartItem]
    let totalPrice: Int
    let status: OrderStatus
    let date: Date
    
    var formattedTotalPrice: String {
        "\(totalPrice) ₽"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    var statusText: String {
        switch status {
        case .placed: return "Размещён"
        case .preparing: return "Готовится"
        case .ready: return "Готов"
        case .completed: return "Завершён"
        case .cancelled: return "Отменён"
        }
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case placed = "placed"
    case preparing = "preparing" 
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"
}

// MARK: - Extensions

extension ModernCartManager {
    
    func canPlaceOrder() -> Bool {
        return !cartItems.isEmpty && !isLoading
    }
    
    func getCartItemCount(for product: Product) -> Int {
        return cartItems.first { $0.menuItem.name == product.name }?.quantity ?? 0
    }
    
    func hasItemInCart(product: Product) -> Bool {
        return cartItems.contains { $0.menuItem.name == product.name }
    }
} 