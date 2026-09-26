import SwiftUI

/// Artwork loaded from the network, with a generated placeholder while loading or when
/// there's no image.
public struct RemoteImage<Placeholder: View>: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let placeholder: Placeholder

    @State private var loaded: LoadedImage?
    @Environment(\.displayScale) private var displayScale

    public init(url: URL?, contentMode: ContentMode = .fill, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                placeholder
                    .frame(width: proxy.size.width, height: proxy.size.height)
                if let loaded, loaded.url == url {
                    Image(decorative: loaded.image.cgImage, scale: displayScale)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .transition(.opacity)
                }
            }
            .clipped()
            .task(id: TaskKey(url: url, size: proxy.size)) {
                await load(size: proxy.size)
            }
        }
    }

    private func load(size: CGSize) async {
        guard let url, size.width > 0, size.height > 0 else {
            loaded = nil
            return
        }
        let maxPixelSize = Int((max(size.width, size.height) * displayScale).rounded(.up))
        guard let image = await ImagePipeline.shared.image(at: url, maxPixelSize: maxPixelSize),
              !Task.isCancelled
        else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            loaded = LoadedImage(url: url, image: image)
        }
    }

    private struct LoadedImage {
        let url: URL
        let image: DecodedImage
    }

    private struct TaskKey: Equatable {
        let url: URL?
        // Rounded so tiny layout changes don't reload the image.
        let width: Int
        let height: Int

        init(url: URL?, size: CGSize) {
            self.url = url
            width = Int(size.width / 20)
            height = Int(size.height / 20)
        }
    }
}

/// A gradient with the title and an icon, standing in for missing artwork.
public struct ArtworkPlaceholder: View {
    private let title: String
    private let systemImage: String
    private let showsTitle: Bool

    public init(title: String, systemImage: String, showsTitle: Bool = true) {
        self.title = title
        self.systemImage = systemImage
        self.showsTitle = showsTitle
    }

    public var body: some View {
        ZStack {
            LinearGradient(colors: Palette.placeholderGradient(seed: title), startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title)
                    .imageScale(.large)
                if showsTitle {
                    Text(title)
                        .appFont(.caption, weight: .semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 8)
                }
            }
            .foregroundStyle(.white.opacity(0.85))
        }
        .accessibilityHidden(true)
    }
}
