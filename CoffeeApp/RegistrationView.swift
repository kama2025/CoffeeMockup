import SwiftUI

struct RegistrationView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(ColorTheme.current.accent)
                        
                        Text("Создать аккаунт")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(ColorTheme.current.textPrimary)
                        
                        Text("Присоединяйтесь к нашей кофейне")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(ColorTheme.current.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Форма регистрации
                    VStack(spacing: 16) {
                        // Имя
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Имя")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(ColorTheme.current.textPrimary)
                            
                            TextField("Ваше имя", text: $name)
                                .textFieldStyle(CoffeeTextFieldStyle())
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        
                        // Email
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
                        
                        // Телефон
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Телефон")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(ColorTheme.current.textPrimary)
                            
                            TextField("+7 (999) 123-45-67", text: $phone)
                                .textFieldStyle(CoffeeTextFieldStyle())
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }
                        
                        // Пароль
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(ColorTheme.current.textPrimary)
                            
                            SecureField("Минимум 6 символов", text: $password)
                                .textFieldStyle(CoffeeTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                        
                        // Подтверждение пароля
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Подтвердите пароль")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(ColorTheme.current.textPrimary)
                            
                            SecureField("Повторите пароль", text: $confirmPassword)
                                .textFieldStyle(CoffeeTextFieldStyle())
                                .textContentType(.newPassword)
                        }
                        
                        // Ошибка валидации пароля
                        if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Пароли не совпадают")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(ColorTheme.current.error)
                        }
                        
                        if !password.isEmpty && password.count < 6 {
                            Text("Пароль должен содержать минимум 6 символов")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(ColorTheme.current.error)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Кнопки
                    VStack(spacing: 16) {
                        // Кнопка регистрации
                        Button(action: registerAction) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.current.textOnPrimary))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Создать аккаунт")
                                        .font(DesignSystem.Typography.headline)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading || !isFormValid)
                        
                        // Кнопка отмены
                        Button(action: { dismiss() }) {
                            Text("Отмена")
                                .font(DesignSystem.Typography.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    // Дополнительная информация
                    VStack(spacing: 8) {
                        Text("Создавая аккаунт, вы соглашаетесь с")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorTheme.current.textSecondary)
                        
                        Text("условиями использования и политикой конфиденциальности")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(ColorTheme.current.accent)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .background(ColorTheme.current.background)
            .navigationTitle("Регистрация")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.current.primary)
                }
            }
        }
        .alert("Ошибка регистрации", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        isValidEmail(email) &&
        !phone.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    // MARK: - Actions
    
    private func registerAction() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                try await authService.register(
                    name: name,
                    email: email,
                    phone: phone,
                    password: password
                )
                
                // Успешная регистрация - закрываем экран
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Preview

#Preview {
    RegistrationView()
} 