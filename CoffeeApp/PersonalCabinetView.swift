import SwiftUI

struct PersonalCabinetView: View {
    @State private var userName = "Иван Петров"
    @State private var userEmail = "ivan.petrov@example.com"
    @State private var loyaltyPoints = 150
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConfig.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Профиль пользователя
                        ProfileHeader()
                        
                        // Программа лояльности
                        LoyaltyCard()
                        
                        // Меню настроек
                        SettingsMenu()
                    }
                    .padding()
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack(spacing: 16) {
            // Аватар
            ZStack {
                Circle()
                    .fill(AppConfig.accentColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Text("ИП")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppConfig.accentColor)
            }
            
            VStack(spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppConfig.textColor)
                
                Text(userEmail)
                    .font(.subheadline)
                    .foregroundColor(AppConfig.textColor.opacity(0.7))
            }
            
            Button("Редактировать профиль") {
                showingEditProfile = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(AppConfig.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userName: $userName, userEmail: $userEmail)
        }
    }
    
    @ViewBuilder
    private func LoyaltyCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💎 Программа лояльности")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Ваши баллы")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(loyaltyPoints) баллов")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("До следующего уровня: \(250 - loyaltyPoints) баллов")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            // Прогресс бар
            ProgressView(value: Double(loyaltyPoints), total: 250)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppConfig.accentColor, AppConfig.primaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func SettingsMenu() -> some View {
        VStack(spacing: 12) {
            SettingsRow(icon: "bell.fill", title: "Уведомления", action: {})
            SettingsRow(icon: "heart.fill", title: "Избранное", action: {})
            SettingsRow(icon: "questionmark.circle.fill", title: "Поддержка", action: {})
            SettingsRow(icon: "info.circle.fill", title: "О приложении", action: {})
            
            Divider()
                .padding(.vertical, 8)
            
            SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Выйти", textColor: .red, action: {
                // Заглушка для выхода
                print("Выход из аккаунта")
            })
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: AppConfig.primaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var textColor: Color = AppConfig.textColor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppConfig.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppConfig.textColor.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
    }
}

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Личная информация") {
                    TextField("Имя", text: $userName)
                    TextField("Email", text: $userEmail)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    PersonalCabinetView()
} 