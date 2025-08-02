import Foundation
import Combine

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String
    let phone: String?
    let loyaltyPoints: Int
    let totalOrders: Int
    let totalSpent: Double
    let isActive: Bool
    let emailVerified: Bool
    let createdAt: String
    let updatedAt: String
    let lastLogin: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, phone
        case loyaltyPoints = "loyalty_points"
        case totalOrders = "total_orders"
        case totalSpent = "total_spent"
        case isActive = "is_active"
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastLogin = "last_login"
    }
}

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userExists
    case networkError
    case invalidResponse
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .userExists:
            return "Пользователь с таким email уже существует"
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .tokenExpired:
            return "Сессия истекла. Войдите заново"
        }
    }
}

// MARK: - AuthService
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isGuestMode: Bool = false
    
    private let baseURL = "http://localhost:3000/api"
    private let tokenKey = "auth_token"
    private let userKey = "current_user"
    
    private init() {
        loadAuthData()
    }
    
    // MARK: - Registration
    func register(name: String, email: String, phone: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "name": name,
            "email": email,
            "phone": phone,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        if httpResponse.statusCode == 409 {
            throw AuthError.userExists
        }
        
        guard httpResponse.statusCode == 201 else {
            throw AuthError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        await MainActor.run {
            self.currentUser = authResponse.user
            self.isAuthenticated = true
            self.saveAuthData(token: authResponse.token, user: authResponse.user)
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        await MainActor.run {
            self.currentUser = authResponse.user
            self.isAuthenticated = true
            self.saveAuthData(token: authResponse.token, user: authResponse.user)
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(name: String, phone: String) async throws {
        guard let token = getToken() else {
            throw AuthError.tokenExpired
        }
        
        let url = URL(string: "\(baseURL)/auth/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = [
            "name": name,
            "phone": phone
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }
        
        let updatedUser = try JSONDecoder().decode(User.self, from: data)
        
        await MainActor.run {
            self.currentUser = updatedUser
            self.saveUserData(user: updatedUser)
        }
    }
    
    // MARK: - Logout
    func logout() {
        currentUser = nil
        isAuthenticated = false
        isGuestMode = false
        clearAuthData()
    }
    
    // MARK: - Token Management
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    private func saveAuthData(token: String, user: User) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        saveUserData(user: user)
    }
    
    private func saveUserData(user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }
    
    func loadAuthData() {
        guard let _ = UserDefaults.standard.string(forKey: tokenKey),
              let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    private func clearAuthData() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}

// MARK: - Auth Response Model
private struct AuthResponse: Codable {
    let token: String
    let user: User
} 