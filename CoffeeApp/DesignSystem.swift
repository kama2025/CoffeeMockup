import SwiftUI

// MARK: - Color Extension для работы с HEX-кодами
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Импортируем протоколы цветовых тем (временно встроим их здесь для исправления компиляции)

protocol ColorThemeProtocol {
    // Primary colors
    var primary: Color { get }
    var primaryLight: Color { get }
    var primaryDark: Color { get }
    
    // Accent colors
    var accent: Color { get }
    var accentLight: Color { get }
    var accentDark: Color { get }
    
    // Background colors
    var background: Color { get }
    var backgroundSecondary: Color { get }
    var surface: Color { get }
    
    // Text colors
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }
    var textOnPrimary: Color { get }
    
    // Status colors
    var success: Color { get }
    var warning: Color { get }
    var error: Color { get }
    var info: Color { get }
    
    // Shadow colors
    var shadowLight: Color { get }
    var shadowMedium: Color { get }
    var shadowHeavy: Color { get }
}

struct CoffeeTheme: ColorThemeProtocol {  //Настройка цветов
    let primary = Color(red: 0.40, green: 0.26, blue: 0.13) // Кофейный
    let primaryLight = Color(red: 0.50, green: 0.36, blue: 0.23)
    let primaryDark = Color(red: 0.30, green: 0.16, blue: 0.03)
    
    let accent = Color(red: 0.96, green: 0.73, blue: 0.29) // Золотистый
    let accentLight = Color(red: 0.98, green: 0.83, blue: 0.39)
    let accentDark = Color(red: 0.86, green: 0.63, blue: 0.19)
    
    let background = Color(red: 0.97, green: 0.95, blue: 0.92)
    let backgroundSecondary = Color(red: 0.99, green: 0.98, blue: 0.96)
    let surface = Color.white
    
    let textPrimary = Color(red: 0.20, green: 0.10, blue: 0.05)
    let textSecondary = Color(red: 0.40, green: 0.26, blue: 0.13).opacity(0.7)
    let textTertiary = Color(red: 0.40, green: 0.26, blue: 0.13).opacity(0.5)
    let textOnPrimary = Color.white
    
    let success = Color.green
    let warning = Color.orange
    let error = Color.red
    let info = Color.blue
    
    let shadowLight = Color.black.opacity(0.08)
    let shadowMedium = Color.black.opacity(0.12)
    let shadowHeavy = Color.black.opacity(0.16)
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: ColorThemeProtocol = CoffeeTheme()
    
    static let availableThemes: [String: ColorThemeProtocol] = [
        "coffee": CoffeeTheme()
    ]
    
    func setTheme(_ themeName: String) {
        if let theme = ThemeManager.availableThemes[themeName] {
            currentTheme = theme
        }
    }
    
    func setTheme(_ theme: ColorThemeProtocol) {
        currentTheme = theme
    }
}

// MARK: - Color Theme (единственный источник цветов для всего приложения)

struct ColorTheme {
    // Динамическая тема - теперь берется из ThemeManager
    private static var themeManager = ThemeManager()
    
    static var current: ColorThemeProtocol {
        return themeManager.currentTheme
    }
    
    // Простой доступ к цветам (для обратной совместимости)
    static var primary: Color { current.primary }
    static var primaryLight: Color { current.primaryLight }
    static var primaryDark: Color { current.primaryDark }
    
    static var accent: Color { current.accent }
    static var accentLight: Color { current.accentLight }
    static var accentDark: Color { current.accentDark }
    
    static var background: Color { current.background }
    static var backgroundSecondary: Color { current.backgroundSecondary }
    static var surface: Color { current.surface }
    
    static var textPrimary: Color { current.textPrimary }
    static var textSecondary: Color { current.textSecondary }
    static var textTertiary: Color { current.textTertiary }
    static var textOnPrimary: Color { current.textOnPrimary }
    
    static var success: Color { current.success }
    static var warning: Color { current.warning }
    static var error: Color { current.error }
    static var info: Color { current.info }
    
    static var shadowLight: Color { current.shadowLight }
    static var shadowMedium: Color { current.shadowMedium }
    static var shadowHeavy: Color { current.shadowHeavy }
    
    // Функции для смены темы
    static func setTheme(_ themeName: String) {
        themeManager.setTheme(themeName)
    }
    
    static func setCustomTheme(_ theme: ColorThemeProtocol) {
        themeManager.setTheme(theme)
    }
}

// MARK: - Design System

struct DesignSystem {
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 50
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    // MARK: - Legacy Support (для обратной совместимости, постепенно заменить на ColorTheme)
    static let primaryFallback = ColorTheme.primary
    static let accentFallback = ColorTheme.accent
    static let surfaceFallback = ColorTheme.backgroundSecondary
    static let backgroundFallback = ColorTheme.background
    static let onPrimary = ColorTheme.textOnPrimary
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(ColorTheme.textOnPrimary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isEnabled ? ColorTheme.primary : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(ColorTheme.primary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(ColorTheme.primary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style

struct CardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.md) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ColorTheme.surface)
                    .shadow(color: ColorTheme.shadowLight, radius: 8, x: 0, y: 4)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.md) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Custom Badge Style

struct BadgeView: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = ColorTheme.accent) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundColor(.orange)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(ColorTheme.primary)
            )
    }
}

// MARK: - Loading State

struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.primary))
            
            Text("Загрузка...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(ColorTheme.textSecondary)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(ColorTheme.surface)
                .shadow(color: ColorTheme.shadowMedium, radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Error State

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(ColorTheme.error)
            
            Text("Ошибка")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(ColorTheme.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Повторить", action: onRetry)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(ColorTheme.surface)
                .shadow(color: ColorTheme.shadowMedium, radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Custom Shimmer Effect

struct ShimmerEffect: View {
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
} 