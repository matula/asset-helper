import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Service for optimizing PNG files using native macOS compression
class PNGCompressor {

    enum CompressionError: LocalizedError {
        case invalidImage
        case compressionFailed
        case fileWriteFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not load PNG image"
            case .compressionFailed:
                return "Failed to compress image"
            case .fileWriteFailed:
                return "Failed to write compressed file"
            }
        }
    }

    /// Compression quality levels (0-6, matching oxipng conventions)
    /// 0 = Fastest, minimal compression
    /// 6 = Best compression, slower
    static let compressionLevels = [0, 1, 2, 3, 4, 5, 6]

    /// Compress a PNG file with specified quality level
    /// - Parameters:
    ///   - sourceURL: Source PNG file
    ///   - destinationURL: Destination for compressed PNG
    ///   - level: Compression level (0-6)
    /// - Returns: Compression statistics (original size, new size, savings)
    func compressPNG(sourceURL: URL, destinationURL: URL, level: Int) throws -> CompressionStats {
        let fileManager = FileManager.default

        // Get original file size
        let originalSize = (try fileManager.attributesOfItem(atPath: sourceURL.path)[.size] as? NSNumber)?.intValue ?? 0

        // Load the source image (as an image source to preserve palette/bit depth when possible)
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw CompressionError.invalidImage
        }

        // Create a temporary destination URL in the same directory
        let tempURL = destinationURL.deletingLastPathComponent().appendingPathComponent("temp_\(UUID().uuidString).png")

        // Create destination for PNG
        guard let destination = CGImageDestinationCreateWithURL(
            tempURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw CompressionError.compressionFailed
        }

        // Configure PNG properties correctly using the PNG dictionary
        // Map UI level to a valid PNG filter strategy (0...4 specific filters, 5 = adaptive)
        let filter = mapPNGFilter(level)
        let pngProps: [CFString: Any] = [
            kCGImagePropertyPNGInterlaceType: 0,            // no interlace
            kCGImagePropertyPNGCompressionFilter: filter    // 0...5 (5 = adaptive)
        ]
        let props: [CFString: Any] = [
            kCGImagePropertyPNGDictionary: pngProps
        ]

        // Add the image directly from source to preserve color model/palette where possible
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, props as CFDictionary)

        // Finalize the temporary file
        guard CGImageDestinationFinalize(destination) else {
            throw CompressionError.fileWriteFailed
        }

        // Get new file size
        let newSize = (try fileManager.attributesOfItem(atPath: tempURL.path)[.size] as? NSNumber)?.intValue ?? 0

        // No-regression: keep the smaller of original and recompressed
        if newSize < originalSize {
            // Ensure destination directory exists
            try? fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            // Remove any existing destination
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            return CompressionStats(
                originalSize: originalSize,
                compressedSize: newSize,
                level: level
            )
        } else {
            // Not smaller; discard temp and copy original to destination (so caller still gets a file)
            try? fileManager.removeItem(at: tempURL)
            if destinationURL != sourceURL {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
            return CompressionStats(
                originalSize: originalSize,
                compressedSize: originalSize,
                level: level
            )
        }
    }

    /// Map UI compression level (0-6) to a PNG filter strategy (0...5)
    /// 0 = None, 1 = Sub, 2 = Up, 3 = Average, 4 = Paeth, 5 = Adaptive
    private func mapPNGFilter(_ level: Int) -> Int {
        switch level {
        case 0: return 0 // None (fastest)
        case 1: return 1 // Sub
        case 2: return 2 // Up
        case 3: return 3 // Average
        case 4: return 4 // Paeth
        default: return 5 // Adaptive (let encoder choose per-row)
        }
    }

    /// Compress PNG in-place (overwrites original)
    func compressPNGInPlace(fileURL: URL, level: Int) throws -> CompressionStats {
        let fileManager = FileManager.default

        // Get original file size
        let originalSize = (try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.intValue ?? 0

        // Load source as image source
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw CompressionError.invalidImage
        }

        // Temp file alongside the original
        let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent("temp_\(UUID().uuidString).png")

        // Create destination
        guard let destination = CGImageDestinationCreateWithURL(
            tempURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw CompressionError.compressionFailed
        }

        // PNG properties
        let filter = mapPNGFilter(level)
        let pngProps: [CFString: Any] = [
            kCGImagePropertyPNGInterlaceType: 0,
            kCGImagePropertyPNGCompressionFilter: filter
        ]
        let props: [CFString: Any] = [
            kCGImagePropertyPNGDictionary: pngProps
        ]

        // Add from source and finalize
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, props as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw CompressionError.fileWriteFailed
        }

        // Compare sizes
        let newSize = (try fileManager.attributesOfItem(atPath: tempURL.path)[.size] as? NSNumber)?.intValue ?? 0

        if newSize < originalSize {
            // Replace original with compressed
            try fileManager.removeItem(at: fileURL)
            try fileManager.moveItem(at: tempURL, to: fileURL)
            return CompressionStats(
                originalSize: originalSize,
                compressedSize: newSize,
                level: level
            )
        } else {
            // No savings; keep original and discard temp
            try? fileManager.removeItem(at: tempURL)
            return CompressionStats(
                originalSize: originalSize,
                compressedSize: originalSize,
                level: level
            )
        }
    }
}

// MARK: - Compression Statistics

struct CompressionStats {
    let originalSize: Int
    let compressedSize: Int
    let level: Int

    var savedBytes: Int {
        originalSize - compressedSize
    }

    var savingsPercentage: Double {
        guard originalSize > 0 else { return 0.0 }
        return Double(savedBytes) / Double(originalSize) * 100.0
    }

    var originalSizeMB: Double {
        Double(originalSize) / 1_048_576.0
    }

    var compressedSizeMB: Double {
        Double(compressedSize) / 1_048_576.0
    }

    var savedBytesMB: Double {
        Double(savedBytes) / 1_048_576.0
    }

    /// Format file size for display
    static func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
