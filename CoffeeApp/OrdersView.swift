import SwiftUI

struct OrdersView: View {
    @ObservedObject var cartManager = ModernCartManager.shared
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                if authService.isGuestMode || authService.currentUser == nil {
                    GuestOrdersView()
                } else if cartManager.orderHistory.isEmpty {
                    EmptyOrdersView()
                } else {
                    OrdersList()
                }
            }
            .navigationTitle("Мои заказы")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private func OrdersList() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(cartManager.orderHistory.reversed()) { order in
                    OrderCard(order: order)
                }
            }
            .padding()
        }
    }
}

struct GuestOrdersView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundColor(AppConfig.textColor.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("Требуется авторизация")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppConfig.textColor)
                
                Text("Войдите в аккаунт, чтобы видеть историю заказов")
                    .font(.body)
                    .foregroundColor(AppConfig.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                authService.isGuestMode = false
            }) {
                Text("Войти в аккаунт")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppConfig.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
    }
}

struct EmptyOrdersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(AppConfig.textColor.opacity(0.3))
            
            Text("Заказов пока нет")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppConfig.textColor)
            
            Text("Ваши заказы будут отображаться здесь")
                .font(.body)
                .foregroundColor(AppConfig.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

struct OrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок заказа
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Заказ №\(order.number)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.textColor)
                    
                    Text(order.formattedDate)
                        .font(.caption)
                        .foregroundColor(AppConfig.textColor.opacity(0.6))
                }
                
                Spacer()
                
                // Статус заказа
                Text(order.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(order.status).opacity(0.2))
                    .foregroundColor(statusColor(order.status))
                    .cornerRadius(8)
            }
            
            // Список товаров
            VStack(alignment: .leading, spacing: 8) {
                Text("Состав заказа:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppConfig.textColor)
                
                ForEach(order.items) { item in
                    HStack {
                        Text("• \(item.menuItem.name)")
                            .font(.body)
                            .foregroundColor(AppConfig.textColor.opacity(0.8))
                        
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(AppConfig.accentColor)
                        }
                        
                        Spacer()
                        
                        Text(item.formattedTotalPrice)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(AppConfig.textColor)
                    }
                }
            }
            
            Divider()
            
            // Итого
            HStack {
                Text("Итого:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppConfig.textColor)
                
                Spacer()
                
                Text(order.formattedTotalPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .placed: return .blue
        case .preparing: return .orange
        case .ready: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

#Preview {
    OrdersView()
} 