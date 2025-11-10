import Foundation

/// Service for optimizing PNG files using Oxipng
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
    /// 6 = Best compression, slower (uses Zopfli)
    static let compressionLevels = [0, 1, 2, 3, 4, 5, 6]

    private let oxipngBridge = OxipngBridge()

    /// Compress a PNG file with specified quality level
    /// - Parameters:
    ///   - sourceURL: Source PNG file
    ///   - destinationURL: Destination for compressed PNG
    ///   - level: Compression level (0-6)
    /// - Returns: Compression statistics (original size, new size, savings)
    func compressPNG(sourceURL: URL, destinationURL: URL, level: Int) throws -> CompressionStats {
        return try oxipngBridge.compressPNG(sourceURL: sourceURL, destinationURL: destinationURL, level: level)
    }

    /// Compress PNG in-place (overwrites original)
    func compressPNGInPlace(fileURL: URL, level: Int) throws -> CompressionStats {
        return try oxipngBridge.compressPNGInPlace(fileURL: fileURL, level: level)
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
