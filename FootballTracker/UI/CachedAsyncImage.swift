import SwiftUI

/// Singleton cache for images to prevent scroll lagging
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Reasonable limits to prevent memory warnings
        cache.countLimit = 300 
    }
    
    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: NSString(string: key))
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: NSString(string: key))
    }
}

/// A drop-in replacement for standard AsyncImage that caches loaded images in memory.
/// This prevents severe lagging when scrolling Lists in SwiftUI.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let uiImage = image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
                    .onChange(of: url) { oldValue, newValue in
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            image = nil
            return
        }
        
        let urlString = url.absoluteString
        
        // Fast path: synchronous cache hit
        if let cached = ImageCache.shared.get(forKey: urlString) {
            self.image = cached
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let uiImage = UIImage(data: data) else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                
                ImageCache.shared.set(uiImage, forKey: urlString)
                
                await MainActor.run {
                    // Make sure the URL hasn't changed while we were fetching
                    if self.url == url {
                        self.image = uiImage
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}
