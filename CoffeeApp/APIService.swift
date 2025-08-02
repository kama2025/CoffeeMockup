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
        case displayOrder = "displayOrder"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
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
        case categoryId = "categoryId"
        case imageUrl = "imageUrl"
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
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
        case orderId = "orderId"
        case productId = "productId"
        case productName = "productName"
        case productDescription = "productDescription"
        case createdAt = "createdAt"
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
        case customerName = "customerName"
        case customerPhone = "customerPhone"
    }
}

struct OrderCreateResponse: Codable {
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
        case productId = "productId"
        case quantity
    }
}

// MARK: - API Service

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:3000/api"
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0  // 30 секунд вместо стандартных 60
        config.timeoutIntervalForResource = 60.0
        return URLSession(configuration: config)
    }()
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
        
        // Добавляем логирование для отладки
        print("🌐 API Request: \(method.rawValue) \(url.absoluteString)")
        
        return session.dataTaskPublisher(for: request)
            .map { data, response in
                print("📡 API Response received: \(data.count) bytes")
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode)")
                }
                return data
            }
            .decode(type: APIResponse<T>.self, decoder: JSONDecoder())
            .mapError { error in
                print("❌ API Error: \(error.localizedDescription)")
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
        notes: String? = nil,
        authToken: String? = nil
    ) -> AnyPublisher<Order, APIError> {
        guard let url = URL(string: "\(baseURL)/orders") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        // Создаем запрос с данными заказа
        let orderData: [String: Any] = [
            "items": items.map { item in
                [
                    "productId": item.menuItem.productId ?? 1,
                    "quantity": item.quantity
                ]
            },
            "customerName": customerName ?? "",
            "customerPhone": customerPhone ?? "",
            "notes": notes ?? ""
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Добавляем авторизационный токен, если он есть
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: orderData)
        } catch {
            return Fail(error: APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: APIResponse<OrderCreateResponse>.self, decoder: JSONDecoder())
            .tryMap { response in
                if response.success, let orderData = response.data {
                    return Order(
                        id: UUID(),
                        number: orderData.id,
                        items: items,
                        totalPrice: Int(orderData.totalPrice),
                        status: .placed,
                        date: Date()
                    )
                } else {
                    throw APIError.serverError(response.message ?? "Ошибка создания заказа")
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.decodingError
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
    
    private func convertToOrder(from apiResponse: OrderCreateResponse, cartItems: [CartItem]) -> Order {
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
    case authenticationRequired(String)
    
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
        case .authenticationRequired(let message):
            return message
        }
    }
}

// CartItem struct defined in CartManager.swift 