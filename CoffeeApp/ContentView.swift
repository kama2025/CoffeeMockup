import SwiftUI

struct ContentView: View {
    @StateObject private var cartManager = ModernCartManager.shared
    @State private var cartBadgeScale: Double = 1.0
    
    var body: some View {
        TabView {
            ModernMenuView()
                .tabItem {
                    Label("Меню", systemImage: "menucard.fill")
                }
            
            CartView()
                .tabItem {
                    VStack {
                        ZStack {
                            Image(systemName: "cart.fill")
                            
                            if cartManager.totalItems > 0 {
                                Text("\(cartManager.totalItems)")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(ColorTheme.textOnPrimary)
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(ColorTheme.error))
                                    .offset(x: 8, y: -8)
                                    .scaleEffect(cartBadgeScale)
                                    .animation(.bouncy(duration: 0.5, extraBounce: 0.3), value: cartManager.totalItems)
                            }
                        }
                        Text("Корзина")
                    }
                }
            
            OrdersView()
                .tabItem {
                    Label("Заказы", systemImage: "doc.text.fill")
                }
            
            PersonalCabinetView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
        .accentColor(ColorTheme.primary)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
} 