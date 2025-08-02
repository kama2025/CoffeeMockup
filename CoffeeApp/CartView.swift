import SwiftUI

struct CartView: View {
    @ObservedObject var cartManager = ModernCartManager.shared
    @State private var showingOrderConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isAuthenticationError = false
    @State private var showingLoginView = false
    @State private var showingRegistrationView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                if cartManager.cartItems.isEmpty {
                    EmptyCartView()
                } else {
                    CartContentView()
                }
            }
            .navigationTitle("Корзина")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Заказ оформлен!", isPresented: $showingOrderConfirmation) {
            Button("OK") { }
        } message: {
            Text("Ваш заказ принят в обработку. Спасибо за покупку!")
        }
        .alert(isAuthenticationError ? "Требуется авторизация" : "Ошибка", isPresented: $showingError) {
            if isAuthenticationError {
                Button("Войти") { 
                    showingError = false
                    showingLoginView = true
                }
                Button("Зарегистрироваться") { 
                    showingError = false
                    showingRegistrationView = true
                }
                Button("Отмена", role: .cancel) { }
            } else {
                Button("OK") { }
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingLoginView) {
            LoginView()
        }
        .sheet(isPresented: $showingRegistrationView) {
            RegistrationView()
        }
    }
    
    @ViewBuilder
    private func CartContentView() -> some View {
        VStack(spacing: 0) {
            // Список товаров
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(cartManager.cartItems) { cartItem in
                        CartItemRow(cartItem: cartItem)
                    }
                }
                .padding()
            }
            
            // Итого и кнопка заказа
            VStack(spacing: 16) {
                Divider()
                
                HStack {
                    Text("Итого:")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppConfig.textColor)
                    
                    Spacer()
                    
                    Text(cartManager.formattedTotalPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppConfig.accentColor)
                }
                .padding(.horizontal)
                
                Button(action: {
                    cartManager.placeOrder(customerName: nil, customerPhone: nil, notes: nil) { result in
                        switch result {
                        case .success(_):
                            showingOrderConfirmation = true
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                            // Проверяем, является ли это ошибкой аутентификации
                            if case .authenticationRequired = error {
                                isAuthenticationError = true
                            } else {
                                isAuthenticationError = false
                            }
                            showingError = true
                        }
                    }
                }) {
                    HStack {
                        Text("Оформить заказ")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "creditcard.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppConfig.accentColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            .background(Color.white)
        }
    }
}

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(AppConfig.textColor.opacity(0.3))
            
            Text("Корзина пуста")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppConfig.textColor)
            
            Text("Добавьте товары из меню")
                .font(.body)
                .foregroundColor(AppConfig.textColor.opacity(0.7))
        }
    }
}

struct CartItemRow: View {
    let cartItem: CartItem
    @ObservedObject var cartManager = ModernCartManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка
            ZStack {
                Circle()
                    .fill(AppConfig.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(getItemEmoji(cartItem.menuItem.name))
                    .font(.title3)
            }
            
            // Информация о товаре
            VStack(alignment: .leading, spacing: 4) {
                Text(cartItem.menuItem.name)
                    .font(.headline)
                    .foregroundColor(AppConfig.textColor)
                
                Text(cartItem.menuItem.formattedPrice)
                    .font(.subheadline)
                    .foregroundColor(AppConfig.textColor.opacity(0.7))
            }
            
            Spacer()
            
            // Контролы количества
            HStack(spacing: 12) {
                Button(action: {
                    cartManager.updateQuantity(cartItem: cartItem, quantity: cartItem.quantity - 1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppConfig.accentColor)
                }
                
                Text("\(cartItem.quantity)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppConfig.textColor)
                    .frame(minWidth: 30)
                
                Button(action: {
                    cartManager.updateQuantity(cartItem: cartItem, quantity: cartItem.quantity + 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppConfig.accentColor)
                }
            }
            
            // Общая стоимость
            Text(cartItem.formattedTotalPrice)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.accentColor)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Удалить") {
                cartManager.removeFromCart(cartItem: cartItem)
            }
            .tint(.red)
        }
    }
    
    private func getItemEmoji(_ name: String) -> String {
        switch name.lowercased() {
        case let x where x.contains("эспрессо"): return "☕️"
        case let x where x.contains("американо"): return "☕️"
        case let x where x.contains("капучино"): return "🥛"
        case let x where x.contains("латте"): return "🥛"
        case let x where x.contains("раф"): return "☕️"
        case let x where x.contains("чизкейк"): return "🍰"
        case let x where x.contains("тирамису"): return "🍰"
        case let x where x.contains("эклер"): return "🧁"
        case let x where x.contains("макарон"): return "🍪"
        case let x where x.contains("круассан"): return "🥐"
        case let x where x.contains("сэндвич"): return "🥪"
        case let x where x.contains("салат"): return "🥗"
        default: return "🍽️"
        }
    }
}

#Preview {
    CartView()
} 