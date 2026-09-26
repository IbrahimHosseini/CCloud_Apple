import CoreGraphics
import Foundation
import ImageIO

/// A decoded image, downsampled to the size it's shown at.
public struct DecodedImage: @unchecked Sendable {
    // CGImage is immutable, so sharing it across threads is safe.
    public let cgImage: CGImage
}

/// Downloads and decodes artwork off the main thread, with memory and disk caches.
///
/// Posters are decoded at display size (not the full file size) to keep scrolling smooth
/// and memory low on large grids.
public actor ImagePipeline {
    public static let shared = ImagePipeline()

    private let session: URLSession
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private var inFlight: [String: Task<DecodedImage?, Never>] = [:]

    public init(memoryCapacity: Int = 64 << 20, diskCapacity: Int = 512 << 20) {
        let configuration = URLSessionConfiguration.default
        // On tvOS the cache directory is purgeable, which is fine for artwork.
        configuration.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: diskCapacity)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        session = URLSession(configuration: configuration)
        memoryCache.totalCostLimit = memoryCapacity
    }

    /// The image at `url`, decoded so its longer side is at most `maxPixelSize` pixels.
    /// `nil` if it can't be loaded.
    public func image(at url: URL, maxPixelSize: Int) async -> DecodedImage? {
        let key = "\(url.absoluteString)#\(maxPixelSize)"
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached.image
        }
        if let task = inFlight[key] {
            return await task.value
        }
        // Detached, so downloads and decoding run in parallel instead of on this actor.
        let task = Task.detached(priority: .userInitiated) { [session] () -> DecodedImage? in
            guard let (data, response) = try? await session.data(from: url),
                  (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true
            else { return nil }
            return Self.decode(data, maxPixelSize: maxPixelSize)
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            let cost = image.cgImage.bytesPerRow * image.cgImage.height
            memoryCache.setObject(CacheEntry(image), forKey: key as NSString, cost: cost)
        }
        return image
    }

    private static func decode(_ data: Data, maxPixelSize: Int) -> DecodedImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 1),
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return DecodedImage(cgImage: image)
    }

    private final class CacheEntry {
        let image: DecodedImage
        init(_ image: DecodedImage) { self.image = image }
    }
}
