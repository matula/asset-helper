import Foundation
import AppKit

/// Service for converting PNG images to ICO format
class IconConverter {

    enum ConversionError: LocalizedError {
        case invalidImage
        case resizeFailed
        case writeFailed
        case noResolutionsSelected

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Unable to load image"
            case .resizeFailed:
                return "Failed to resize image"
            case .writeFailed:
                return "Failed to write ICO file"
            case .noResolutionsSelected:
                return "No resolutions selected"
            }
        }
    }

    /// Available ICO resolutions
    static let availableResolutions: [Int] = [16, 32, 48, 64, 128, 256]

    /// Convert a PNG file to ICO format with multiple resolutions
    /// - Parameters:
    ///   - sourceURL: Source PNG file URL
    ///   - destinationURL: Destination ICO file URL
    ///   - resolutions: Array of pixel sizes to include (e.g., [16, 32, 64])
    /// - Throws: ConversionError if the conversion fails
    func convertPNGtoICO(
        sourceURL: URL,
        destinationURL: URL,
        resolutions: [Int]
    ) throws {
        print("DEBUG IconConverter: Starting conversion")
        print("DEBUG IconConverter: Source: \(sourceURL.path)")
        print("DEBUG IconConverter: Destination: \(destinationURL.path)")
        print("DEBUG IconConverter: Resolutions: \(resolutions)")

        guard !resolutions.isEmpty else {
            throw ConversionError.noResolutionsSelected
        }

        // Load source image
        guard let sourceImage = NSImage(contentsOf: sourceURL) else {
            print("DEBUG IconConverter: Failed to load source image")
            throw ConversionError.invalidImage
        }

        print("DEBUG IconConverter: Source image loaded, size: \(sourceImage.size)")

        // Generate PNG data for each resolution
        var imageEntries: [(size: Int, pngData: Data)] = []

        for size in resolutions.sorted() {
            print("DEBUG IconConverter: Processing resolution \(size)x\(size)")

            guard let resizedImage = resize(image: sourceImage, to: CGSize(width: size, height: size)) else {
                print("DEBUG IconConverter: Failed to resize to \(size)x\(size)")
                throw ConversionError.resizeFailed
            }

            guard let pngData = resizedImage.pngData() else {
                print("DEBUG IconConverter: Failed to get PNG data for \(size)x\(size)")
                throw ConversionError.resizeFailed
            }

            print("DEBUG IconConverter: Generated PNG data for \(size)x\(size), size: \(pngData.count) bytes")
            imageEntries.append((size: size, pngData: pngData))
        }

        // Write ICO file
        print("DEBUG IconConverter: Creating ICO data from \(imageEntries.count) entries")
        let icoData = try createICOData(from: imageEntries)
        print("DEBUG IconConverter: ICO data created, size: \(icoData.count) bytes")

        try icoData.write(to: destinationURL)
        print("DEBUG IconConverter: ICO file written successfully")
    }

    /// Resize an NSImage to a specific size with high quality
    private func resize(image: NSImage, to targetSize: CGSize) -> NSImage? {
        let newImage = NSImage(size: targetSize)

        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )

        newImage.unlockFocus()

        return newImage
    }

    /// Create ICO file data from multiple PNG images
    private func createICOData(from entries: [(size: Int, pngData: Data)]) throws -> Data {
        var data = Data()

        // ICONDIR header (6 bytes)
        // Reserved (2 bytes) = 0
        data.append(contentsOf: [0x00, 0x00])
        // Type (2 bytes) = 1 for ICO
        data.append(contentsOf: [0x01, 0x00])
        // Count (2 bytes) = number of images
        let count = UInt16(entries.count)
        data.append(contentsOf: withUnsafeBytes(of: count.littleEndian) { Array($0) })

        // Calculate offset for first image data (after all ICONDIRENTRY structures)
        var imageOffset = 6 + (entries.count * 16)

        // Write ICONDIRENTRY for each image (16 bytes each)
        for entry in entries {
            let width = entry.size > 255 ? 0 : UInt8(entry.size)
            let height = entry.size > 255 ? 0 : UInt8(entry.size)

            // Width (1 byte)
            data.append(width)
            // Height (1 byte)
            data.append(height)
            // Color palette (1 byte) = 0 for PNG
            data.append(0x00)
            // Reserved (1 byte) = 0
            data.append(0x00)
            // Color planes (2 bytes) = 1
            data.append(contentsOf: [0x01, 0x00])
            // Bits per pixel (2 bytes) = 32 for RGBA
            data.append(contentsOf: [0x20, 0x00])
            // Image data size (4 bytes)
            let size = UInt32(entry.pngData.count)
            data.append(contentsOf: withUnsafeBytes(of: size.littleEndian) { Array($0) })
            // Image data offset (4 bytes)
            let offset = UInt32(imageOffset)
            data.append(contentsOf: withUnsafeBytes(of: offset.littleEndian) { Array($0) })

            imageOffset += entry.pngData.count
        }

        // Append all PNG image data
        for entry in entries {
            data.append(entry.pngData)
        }

        return data
    }
}

// MARK: - NSImage PNG Data Extension
extension NSImage {
    /// Convert NSImage to PNG Data
    func pngData() -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = self.size

        return bitmapRep.representation(using: .png, properties: [:])
    }
}
