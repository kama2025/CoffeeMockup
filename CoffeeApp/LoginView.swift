import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingRegistration = false
    

    
    // Колбэк для гостевого режима
    var onGuestMode: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo и заголовок
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 80))
                            .foregroundColor(ColorTheme.current.accent)
                        
                        Text("Добро пожаловать")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(ColorTheme.current.textPrimary)
                        
                        Text("Войдите в свой аккаунт")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(ColorTheme.current.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Форма входа
                    VStack(spacing: 20) {
                        // Email поле
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(ColorTheme.current.textPrimary)
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(CoffeeTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        // Пароль поле
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(ColorTheme.current.textPrimary)
                            
                            SecureField("Введите пароль", text: $password)
                                .textFieldStyle(CoffeeTextFieldStyle())
                                .textContentType(.password)
                        }
                        

                    }
                    .padding(.horizontal, 24)
                    
                    // Кнопки
                    VStack(spacing: 16) {
                        // Кнопка входа
                        Button(action: loginAction) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.current.textOnPrimary))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Войти")
                                        .font(DesignSystem.Typography.headline)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        // Кнопка регистрации
                        Button(action: { showingRegistration = true }) {
                            Text("Создать аккаунт")
                                .font(DesignSystem.Typography.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isLoading)
                        
                        // Гостевой режим
                        Button(action: guestModeAction) {
                            Text("Продолжить как гость")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(ColorTheme.current.textSecondary)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    

                    
                    Spacer()
                }
            }
            .background(ColorTheme.current.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegistration) {
            RegistrationView()
        }
        .alert("Ошибка входа", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func loginAction() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try await authService.login(email: email, password: password)
                // Успешный вход - AuthService обновит состояние
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func guestModeAction() {
        // В гостевом режиме просто устанавливаем флаг, что можно продолжить
        // Приложение покажет основной интерфейс без аутентификации
        authService.currentUser = nil
        authService.isAuthenticated = false
        authService.isGuestMode = true
    }
}

// MARK: - Text Field Style

struct CoffeeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(ColorTheme.current.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ColorTheme.current.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Button Styles are defined in DesignSystem.swift

// MARK: - Preview

#Preview {
    LoginView()
} 