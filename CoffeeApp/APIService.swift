import Foundation
import Combine

// MARK: - API Models

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let pagination: Pagination?
}

struct Pagination: Codable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
    let icon: String
    let displayOrder: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case displayOrder = "display_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Product: Identifiable, Codable {
    let id: Int
    let categoryId: Int
    let name: String
    let description: String?
    let price: Double
    let imageUrl: String?
    let available: Bool
    let featured: Bool
    let categoryName: String?
    let categoryIcon: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, available, featured
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var formattedPrice: String {
        return "\(Int(price)) ₽"
    }
}

// Order struct defined in CartManager.swift

struct OrderItem: Identifiable, Codable {
    let id: Int
    let orderId: Int
    let productId: Int
    let quantity: Int
    let price: Double
    let productName: String?
    let productDescription: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, quantity, price
        case orderId = "order_id"
        case productId = "product_id"
        case productName = "product_name"
        case productDescription = "product_description"
        case createdAt = "created_at"
    }
    
    var totalPrice: Double {
        return price * Double(quantity)
    }
    
    var formattedTotalPrice: String {
        return "\(Int(totalPrice)) ₽"
    }
}

// OrderStatus enum defined in CartManager.swift

struct CreateOrderRequest: Codable {
    let items: [OrderItemRequest]
    let customerName: String?
    let customerPhone: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case items, notes
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
    }
}

struct OrderAPIResponse: Codable {
    let id: Int
    let orderNumber: String
    let totalPrice: Double
    let status: String
    let customerName: String?
    let customerPhone: String?
    let notes: String?
    let items: [OrderItemAPIResponse]
    let itemsCount: Int
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, status, notes, items
        case orderNumber = "orderNumber"
        case totalPrice = "totalPrice"
        case customerName = "customerName"
        case customerPhone = "customerPhone"
        case itemsCount = "itemsCount"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

struct OrderItemAPIResponse: Codable {
    let productId: Int
    let name: String
    let price: Double
    let quantity: Int
    let total: Double
    
    enum CodingKeys: String, CodingKey {
        case name, price, quantity, total
        case productId = "productId"
    }
}

struct OrderItemRequest: Codable {
    let productId: Int
    let quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
    }
}

// MARK: - API Service

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://192.168.31.118:3000/api"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Generic Request Method
    
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil
    ) -> AnyPublisher<APIResponse<T>, APIError> {
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIResponse<T>.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Categories
    
    func fetchCategories() -> AnyPublisher<[Category], APIError> {
        let publisher: AnyPublisher<APIResponse<[Category]>, APIError> = request(endpoint: "/categories")
        return publisher
            .map { response in
                if response.success {
                    return response.data ?? []
                } else {
                    return []
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Products
    
    func fetchProducts(
        categoryId: Int? = nil,
        search: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) -> AnyPublisher<[Product], APIError> {
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        if let categoryId = categoryId {
            queryItems.append(URLQueryItem(name: "category_id", value: "\(categoryId)"))
        }
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        let queryString = queryItems
            .compactMap { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&")
        
        let endpoint = "/products?\(queryString)"
        
        let publisher: AnyPublisher<APIResponse<[Product]>, APIError> = request(endpoint: endpoint)
        return publisher
            .map { response in
                if response.success {
                    return response.data ?? []
                } else {
                    return []
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchProductsByCategory(categoryId: Int) -> AnyPublisher<[Product], APIError> {
        let publisher: AnyPublisher<APIResponse<[Product]>, APIError> = request(endpoint: "/products/category/\(categoryId)")
        return publisher
            .map { response in
                if response.success {
                    return response.data ?? []
                } else {
                    return []
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchFeaturedProducts() -> AnyPublisher<[Product], APIError> {
        let publisher: AnyPublisher<APIResponse<[Product]>, APIError> = request(endpoint: "/products/featured")
        return publisher
            .map { response in
                if response.success {
                    return response.data ?? []
                } else {
                    return []
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Orders
    
    func createOrder(
        items: [CartItem],
        customerName: String? = nil,
        customerPhone: String? = nil,
        notes: String? = nil
    ) -> AnyPublisher<Order, APIError> {
        
        let orderItems = items.map { item in
            OrderItemRequest(
                productId: item.menuItem.productId ?? 0,
                quantity: item.quantity
            )
        }
        
        let requestBody = CreateOrderRequest(
            items: orderItems,
            customerName: customerName,
            customerPhone: customerPhone,
            notes: notes
        )
        
        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        let publisher: AnyPublisher<APIResponse<OrderAPIResponse>, APIError> = request(endpoint: "/orders", method: .POST, body: bodyData)
        return publisher
            .compactMap { response in
                if response.success, let orderData = response.data {
                    return self.convertToOrder(from: orderData, cartItems: items)
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchOrders(
        status: OrderStatus? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) -> AnyPublisher<[Order], APIError> {
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        
        let queryString = queryItems
            .compactMap { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&")
        
        let endpoint = "/orders?\(queryString)"
        
        let publisher: AnyPublisher<APIResponse<[Order]>, APIError> = request(endpoint: endpoint)
        return publisher
            .map { response in
                if response.success {
                    return response.data ?? []
                } else {
                    return []
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchOrderDetails(orderId: Int) -> AnyPublisher<Order, APIError> {
        let publisher: AnyPublisher<APIResponse<Order>, APIError> = request(endpoint: "/orders/\(orderId)")
        return publisher
            .compactMap { response in
                if response.success {
                    return response.data
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func convertToOrder(from apiResponse: OrderAPIResponse, cartItems: [CartItem]) -> Order {
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: apiResponse.createdAt) ?? Date()
        
        let orderStatus = OrderStatus(rawValue: apiResponse.status) ?? .placed
        
        return Order(
            id: UUID(),
            number: apiResponse.id,
            items: cartItems, // Use original cart items since they have the correct structure
            totalPrice: Int(apiResponse.totalPrice),
            status: orderStatus,
            date: date
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(String)
    case decodingError
    case encodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL адрес"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .decodingError:
            return "Ошибка декодирования данных"
        case .encodingError:
            return "Ошибка кодирования данных"
        case .serverError(let message):
            return "Ошибка сервера: \(message)"
        }
    }
}

// CartItem struct defined in CartManager.swift 