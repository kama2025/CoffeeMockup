import SwiftUI

@main
struct CoffeeAppApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var cartManager = ModernCartManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated || authService.isGuestMode {
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(cartManager)
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .onAppear {
                authService.loadAuthData()
            }
        }
    }
} 
