import SwiftUI

struct PersonalCabinetView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingEditProfile = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var user: User? {
        authService.currentUser
    }
    
    private var isGuest: Bool {
        authService.isGuestMode || user == nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Profile Header
                        profileHeader
                        
                        if !isGuest {
                            // User Stats
                            userStats
                            
                            // Loyalty Program
                            loyaltySection
                            
                            // Actions
                            actionsSection
                        } else {
                            // Guest Message
                            guestSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingEditProfile) {
            if !isGuest {
                EditProfileView()
                    .environmentObject(authService)
            }
        }
        .alert("Уведомление", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ColorTheme.primary, ColorTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text(isGuest ? "?" : String(user?.name.prefix(1) ?? "U"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(isGuest ? "Гость" : user?.name ?? "Пользователь")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(ColorTheme.textPrimary)
                
                Text(isGuest ? "Войдите для персонализации" : user?.email ?? "")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            
            if !isGuest {
                Button("Редактировать профиль") {
                    showingEditProfile = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
    }
    
    // MARK: - User Stats
    
    private var userStats: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            StatCard(
                title: "Заказов",
                value: "\(user?.totalOrders ?? 0)",
                icon: "bag.fill"
            )
            
            StatCard(
                title: "Потрачено",
                value: String(format: "%.0f ₽", user?.totalSpent ?? 0),
                icon: "creditcard.fill"
            )
            
            StatCard(
                title: "Баллов",
                value: "\(user?.loyaltyPoints ?? 0)",
                icon: "star.fill"
            )
        }
    }
    
    // MARK: - Loyalty Section
    
    private var loyaltySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(ColorTheme.accent)
                
                Text("Программа лояльности")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(ColorTheme.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Баллы: \(user?.loyaltyPoints ?? 0)")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(ColorTheme.primary)
                
                ProgressView(value: Double(user?.loyaltyPoints ?? 0), total: 500.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: ColorTheme.accent))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("До следующего уровня: \(500 - (user?.loyaltyPoints ?? 0)) баллов")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(ColorTheme.textSecondary)
            }
            
            Text("1 рубль = 1 балл • 100 баллов = 50₽ скидка")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(ColorTheme.textSecondary)
        }
        .cardStyle()
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ActionRow(
                icon: "bell.fill",
                title: "Уведомления",
                subtitle: "Настроить push-уведомления",
                action: { }
            )
            
            ActionRow(
                icon: "questionmark.circle.fill",
                title: "Поддержка",
                subtitle: "Связаться с нами",
                action: { }
            )
            
            ActionRow(
                icon: "info.circle.fill",
                title: "О приложении",
                subtitle: "Версия и информация",
                action: { }
            )
            
            ActionRow(
                icon: "arrow.right.square.fill",
                title: "Выйти",
                subtitle: "Завершить сеанс",
                isDestructive: true,
                action: logout
            )
        }
        .cardStyle()
    }
    
    // MARK: - Guest Section
    
    private var guestSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(ColorTheme.textSecondary)
                
                Text("Гостевой режим")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(ColorTheme.textPrimary)
                
                Text("Войдите в аккаунт для получения баллов лояльности, истории заказов и персональных предложений")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Войти в аккаунт") {
                authService.logout() // Это вернет к экрану входа
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardStyle()
    }
    
    // MARK: - Actions
    
    private func logout() {
        authService.logout()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(ColorTheme.accent)
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.textPrimary)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(ColorTheme.surface)
        )
    }
}

struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? ColorTheme.error : ColorTheme.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(isDestructive ? ColorTheme.error : ColorTheme.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                }
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textTertiary)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Имя", text: $name)
                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                name = authService.currentUser?.name ?? ""
                phone = authService.currentUser?.phone ?? ""
            }
        }
        .alert("Уведомление", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            do {
                try await authService.updateProfile(name: name, phone: phone)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PersonalCabinetView()
        .environmentObject(AuthService.shared)
} 