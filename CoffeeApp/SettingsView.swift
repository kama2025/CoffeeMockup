import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Информация для разработчика
                        DeveloperInfo()
                        
                        // Настройки приложения
                        AppSettings()
                        
                        // Техническая информация
                        TechnicalInfo()
                    }
                    .padding()
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private func DeveloperInfo() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚙️ Информация для разработчика")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "Кастомизация:", value: "Только через код")
                InfoRow(title: "Файл конфигурации:", value: "Config.swift")
                InfoRow(title: "Цвета:", value: "primaryColor, accentColor")
                InfoRow(title: "Меню:", value: "menuCategories массив")
                InfoRow(title: "Адрес кофейни:", value: "cafeAddress, cafePhone")
            }
            
            Text("Для изменения дизайна под кофейню отредактируйте Config.swift и пересоберите проект.")
                .font(.caption)
                .foregroundColor(AppConfig.textColor.opacity(0.7))
                .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func AppSettings() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Настройки приложения")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
            
            VStack(spacing: 12) {
                SettingsToggle(title: "Уведомления", isOn: .constant(true))
                SettingsToggle(title: "Звуки", isOn: .constant(false))
                SettingsToggle(title: "Темная тема", isOn: .constant(false))
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
    private func TechnicalInfo() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Техническая информация")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppConfig.primaryColor)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "Версия:", value: "1.0.0")
                InfoRow(title: "Платформа:", value: "iOS 17.0+")
                InfoRow(title: "Фреймворк:", value: "SwiftUI")
                InfoRow(title: "Архитектура:", value: "MVVM")
            }
            
            Button("Сбросить данные приложения") {
                // Заглушка для сброса
                UserDefaults.standard.removeObject(forKey: "orderHistory")
                print("Данные сброшены")
            }
            .font(.subheadline)
            .foregroundColor(.red)
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(AppConfig.textColor.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(AppConfig.textColor)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(AppConfig.textColor)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(AppConfig.accentColor)
        }
    }
}

#Preview {
    SettingsView()
} 