import SwiftUI
import Combine
import UIKit

struct ModernMenuView: View {
    @StateObject private var viewModel = MenuViewModel()
    @StateObject private var cartManager = ModernCartManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var showingSearch = false
    
    var body: some View {
        NavigationStack {
                    ZStack {
            ColorTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Search
                    headerView
                    
                    // Content
                    switch viewModel.loadingState {
                    case .loading:
                        LoadingView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .error(let message):
                        ErrorView(message: message) {
                            viewModel.loadData()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .loaded:
                        contentView
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .searchable(text: $searchText, isPresented: $showingSearch)
        .onChange(of: searchText) { _ in
            viewModel.searchProducts(query: searchText)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Кофейня")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(ColorTheme.primary)
                    
                    Text("Добро пожаловать!")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(ColorTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: { showingSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(DesignSystem.primaryFallback)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(DesignSystem.surfaceFallback)
                                .shadow(color: ColorTheme.shadowLight, radius: 4, x: 0, y: 2)
                        )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)
            
            // Categories Scroll
            if !viewModel.categories.isEmpty {
                categoriesScrollView
            }
        }
        .background(DesignSystem.backgroundFallback)
    }
    
    // MARK: - Categories Scroll
    
    private var categoriesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // All Categories Button
                CategoryButton(
                    title: "Все",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    viewModel.loadProducts(categoryId: nil)
                }
                
                // Category Buttons
                ForEach(viewModel.categories) { category in
                    CategoryButton(
                        title: category.name,
                        icon: category.icon,
                        isSelected: selectedCategory?.id == category.id
                    ) {
                        selectedCategory = category
                        viewModel.loadProducts(categoryId: category.id)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg) {
                // Featured Products
                if !viewModel.featuredProducts.isEmpty && selectedCategory == nil && searchText.isEmpty {
                    featuredSection
                }
                
                // Products Grid
                productsGrid
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Рекомендуемое")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.primaryFallback)
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(viewModel.featuredProducts) { product in
                        FeaturedProductCard(product: product) {
                            cartManager.addToCart(product: product)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xs)
            }
        }
    }
    
    // MARK: - Products Grid
    
    private var productsGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            if !viewModel.products.isEmpty {
                HStack {
                    Text(selectedCategory?.name ?? "Все товары")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.primaryFallback)
                    
                    Spacer()
                    
                    Text("\(viewModel.products.count) товаров")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.xs)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(viewModel.products) { product in
                        ProductCard(product: product) {
                            cartManager.addToCart(product: product)
                        }
                    }
                }
            } else if !searchText.isEmpty {
                emptySearchView
            }
        }
    }
    
    // MARK: - Empty Search View
    
    private var emptySearchView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Ничего не найдено")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.primaryFallback)
            
            Text("Попробуйте изменить запрос")
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.xxl)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if icon.contains(".") {
                    // SF Symbol
                    Image(systemName: icon)
                        .font(.body)
                } else {
                    // Emoji
                    Text(icon)
                        .font(.body)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : DesignSystem.primaryFallback)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? DesignSystem.primaryFallback : DesignSystem.surfaceFallback)
                    .shadow(color: ColorTheme.shadowLight, radius: isSelected ? 6 : 3, x: 0, y: 2)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

// MARK: - Featured Product Card

struct FeaturedProductCard: View {
    let product: Product
    let onAddToCart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Product Image Placeholder
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.accentFallback.opacity(0.3), DesignSystem.primaryFallback.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.primaryFallback.opacity(0.7))
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(product.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.primaryFallback)
                    .lineLimit(1)
                
                if let description = product.description {
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(product.formattedPrice)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.accentFallback)
                    
                    Spacer()
                    
                    Button(action: {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Call the action
                        onAddToCart()
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(DesignSystem.primaryFallback)
                            )
                    }
                    .scaleEffect(1.0)
                    .animation(DesignSystem.Animation.bounce, value: true)
                }
            }
        }
        .frame(width: 200)
        .cardStyle()
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let onAddToCart: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Product Image Placeholder
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.accentFallback.opacity(0.3), DesignSystem.primaryFallback.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)
                .overlay(
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.primaryFallback.opacity(0.7))
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(product.name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.primaryFallback)
                    .lineLimit(1)
                
                if let description = product.description {
                    Text(description)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(alignment: .bottom) {
                    Text(product.formattedPrice)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.accentFallback)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(DesignSystem.Animation.bounce) {
                            isPressed = true
                        }
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Call the action
                        onAddToCart()
                        
                        // Reset animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(DesignSystem.Animation.spring) {
                                isPressed = false
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(DesignSystem.primaryFallback)
                                    .scaleEffect(isPressed ? 0.9 : 1.0)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .aspectRatio(0.8, contentMode: .fit)
        .cardStyle()
    }
}

// MARK: - View Model

@MainActor
class MenuViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var products: [Product] = []
    @Published var featuredProducts: [Product] = []
    @Published var loadingState: LoadingState = .loading
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum LoadingState {
        case loading
        case loaded
        case error(String)
    }
    
    func loadData() {
        loadingState = .loading
        
        Publishers.CombineLatest3(
            apiService.fetchCategories(),
            apiService.fetchProducts(),
            apiService.fetchFeaturedProducts()
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.loadingState = .error(error.localizedDescription)
                }
            },
            receiveValue: { categories, products, featured in
                self.categories = categories
                self.products = products
                self.featuredProducts = featured
                self.loadingState = .loaded
            }
        )
        .store(in: &cancellables)
    }
    
    func refreshData() async {
        await withCheckedContinuation { continuation in
            loadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume()
            }
        }
    }
    
    func loadProducts(categoryId: Int?) {
        apiService.fetchProducts(categoryId: categoryId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { products in
                    self.products = products
                }
            )
            .store(in: &cancellables)
    }
    
    func searchProducts(query: String) {
        if query.isEmpty {
            loadProducts(categoryId: nil)
        } else {
            apiService.fetchProducts(search: query)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { products in
                        self.products = products
                    }
                )
                .store(in: &cancellables)
        }
    }
} 