import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Логотип и название
                        CafeHeader()
                        
                        // Информация о кафе
                        CafeInfo()
                        
                        // Контакты
                        ContactInfo()
                        
                        // Рабочие часы
                        WorkingHours()
                        
                        // Дополнительная информация
                        AdditionalInfo()
                    }
                    .padding()
                }
            }
            .navigationTitle("О нас")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private func CafeHeader() -> some View {
        VStack(spacing: 16) {
            // Логотип кофейни
            ZStack {
                Circle()
                    .fill(AppConfig.accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text("☕️")
                    .font(.system(size: 50))
            }
            
            VStack(spacing: 8) {
                Text(AppConfig.cafeName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.primaryColor)
                    .multilineTextAlignment(.center)
                
                Text("Место, где рождается настоящий вкус")
                    .font(.subheadline)
                    .foregroundColor(AppConfig.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func CafeInfo() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("О нашей кофейне")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
            
            Text("Мы - уютная кофейня, где каждая чашка кофе готовится с любовью и особым вниманием к деталям. Наши бариста используют только лучшие сорта кофе и следят за каждым этапом приготовления.")
                .font(.body)
                .foregroundColor(AppConfig.textColor)
                .lineSpacing(4)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "leaf.fill", text: "100% натуральные ингредиенты")
                FeatureRow(icon: "cup.and.saucer.fill", text: "Свежеобжаренный кофе")
                FeatureRow(icon: "heart.fill", text: "Домашняя атмосфера")
                FeatureRow(icon: "wifi", text: "Бесплатный Wi-Fi")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func ContactInfo() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Контакты")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
            
            VStack(spacing: 12) {
                ContactRow(icon: "location.fill", title: "Адрес", value: AppConfig.cafeAddress)
                ContactRow(icon: "phone.fill", title: "Телефон", value: AppConfig.cafePhone)
                ContactRow(icon: "envelope.fill", title: "Email", value: "info@coffee-corner.ru")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func WorkingHours() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Режим работы")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
            
            VStack(spacing: 8) {
                WorkingHourRow(day: "Понедельник - Пятница", hours: "7:00 - 22:00")
                WorkingHourRow(day: "Суббота - Воскресенье", hours: "8:00 - 23:00")
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppConfig.accentColor)
                Text("Сейчас открыто")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func AdditionalInfo() -> some View {
        VStack(spacing: 16) {
            // Социальные сети
            VStack(alignment: .leading, spacing: 12) {
                Text("Мы в социальных сетях")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.primaryColor)
                
                HStack(spacing: 20) {
                    SocialButton(icon: "instagram", color: .pink)
                    SocialButton(icon: "telegram", color: .blue)
                    SocialButton(icon: "vk", color: .blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            
            // Версия приложения
            Text("Версия приложения 1.0")
                .font(.caption)
                .foregroundColor(AppConfig.textColor.opacity(0.5))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConfig.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(AppConfig.textColor)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConfig.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppConfig.textColor.opacity(0.7))
                
                Text(value)
                    .font(.body)
                    .foregroundColor(AppConfig.textColor)
            }
            
            Spacer()
        }
    }
}

struct WorkingHourRow: View {
    let day: String
    let hours: String
    
    var body: some View {
        HStack {
            Text(day)
                .font(.body)
                .foregroundColor(AppConfig.textColor)
            
            Spacer()
            
            Text(hours)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(AppConfig.accentColor)
        }
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Заглушка для открытия социальных сетей
            print("Открытие \(icon)")
        }) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "link")
                    .font(.title3)
                    .foregroundColor(color)
            }
        }
    }
}

#Preview {
    AboutView()
} 