import SwiftUI
import UIKit

enum CoverImageStore {
    private static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Covers", isDirectory: true)
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func save(_ image: UIImage, destinationId: UUID) -> String? {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let data = jpegData(from: image) else { return nil }
        let fileName = "\(destinationId.uuidString).jpg"
        do {
            try data.write(to: url(for: fileName), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    static func load(_ fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        guard let data = try? Data(contentsOf: url(for: fileName)) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    private static func jpegData(from image: UIImage, maxDimension: CGFloat = 1400) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        let rendered: UIImage
        if longest > maxDimension, longest > 0 {
            let ratio = maxDimension / longest
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            rendered = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            rendered = image
        }
        return rendered.jpegData(compressionQuality: 0.72)
    }
}

struct DestinationCover: View {
    let fileName: String?
    var fallbackAsset = "BannerFlight"
    var height: CGFloat = 132

    var body: some View {
        Group {
            if let image = CoverImageStore.load(fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(fallbackAsset)
                    .resizable()
                    .scaledToFill()
            }
        }
        .ticketClip(height: height)
    }
}
