import SwiftUI
import UIKit

struct MenuView: View {
    @ObservedObject var cartManager = ModernCartManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Заголовок кофейни
                        VStack(spacing: 8) {
                            Text(AppConfig.cafeName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(AppConfig.primaryColor)
                            
                            Text("Свежий кофе и десерты каждый день")
                                .font(.subheadline)
                                .foregroundColor(AppConfig.textColor.opacity(0.7))
                        }
                        .padding(.top)
                        
                        // Категории меню
                        ForEach(AppConfig.menuCategories, id: \.name) { category in
                            MenuCategoryView(category: category)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MenuCategoryView: View {
    let category: MenuCategory
    @ObservedObject var cartManager = ModernCartManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок категории
            Text(category.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
                .padding(.horizontal)
            
            // Товары в категории
            LazyVStack(spacing: 12) {
                ForEach(category.items) { item in
                    MenuItemCard(item: item)
                }
            }
        }
    }
}

struct MenuItemCard: View {
    let item: MenuItem
    @ObservedObject var cartManager = ModernCartManager.shared
    @State private var isAdded = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка товара
            ZStack {
                Circle()
                    .fill(AppConfig.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(getItemEmoji(item.name))
                    .font(.title2)
            }
            
            // Информация о товаре
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppConfig.textColor)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(AppConfig.textColor.opacity(0.7))
                    .lineLimit(2)
                
                Text(item.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.accentColor)
            }
            
            Spacer()
            
            // Кнопка добавления
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                cartManager.addToCart(item: item)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAdded = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    isAdded = false
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isAdded ? Color.green : AppConfig.accentColor)
                        .frame(width: 70, height: 36)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isAdded ? "checkmark" : "plus")
                            .font(.system(size: 14, weight: .semibold))
                        
                        if !isAdded {
                            Text("В корзину")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(.white)
                }
            }
            .disabled(isAdded)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
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
    MenuView()
} 