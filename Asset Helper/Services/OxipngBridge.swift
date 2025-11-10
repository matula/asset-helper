import Foundation

/// Bridge to Oxipng CLI for PNG compression with progressive optimization
class OxipngBridge {

    enum OxipngError: LocalizedError {
        case invalidImage
        case compressionFailed(String)
        case binaryNotFound

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not load PNG image"
            case .compressionFailed(let message):
                return "Oxipng compression failed: \(message)"
            case .binaryNotFound:
                return "Oxipng binary not found in app bundle"
            }
        }
    }

    private let processRunner = ProcessRunner()

    /// Compress a PNG file using Oxipng with specified quality level
    /// - Parameters:
    ///   - sourceURL: Source PNG file
    ///   - destinationURL: Destination for compressed PNG
    ///   - level: Compression level (0-6)
    /// - Returns: Compression statistics (original size, new size, savings)
    func compressPNG(sourceURL: URL, destinationURL: URL, level: Int) throws -> CompressionStats {
        let fileManager = FileManager.default

        // Get original file size
        let originalSize = try fileManager.attributesOfItem(atPath: sourceURL.path)[.size] as? Int ?? 0

        // Start accessing security-scoped resource for destination directory
        let destParent = destinationURL.deletingLastPathComponent()
        let destAccessing = destParent.startAccessingSecurityScopedResource()
        defer {
            if destAccessing {
                destParent.stopAccessingSecurityScopedResource()
            }
        }

        // Ensure destination directory exists
        try? fileManager.createDirectory(
            at: destParent,
            withIntermediateDirectories: true
        )

        // Create a temporary file in the system temp directory (has write permissions)
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent("oxipng_temp_\(UUID().uuidString).png")

        // Copy source to temp location (oxipng modifies in-place)
        try fileManager.copyItem(at: sourceURL, to: tempURL)

        // Build oxipng arguments based on compression level
        let arguments = buildOxipngArguments(level: level, filePath: tempURL.path)

        do {
            // Run oxipng
            let result = try processRunner.runBundledTool("oxipng", arguments: arguments)

            guard result.succeeded else {
                // Clean up temp file
                try? fileManager.removeItem(at: tempURL)
                throw OxipngError.compressionFailed(result.stderr.isEmpty ? result.stdout : result.stderr)
            }

            // Get compressed file size
            let compressedSize = try fileManager.attributesOfItem(atPath: tempURL.path)[.size] as? Int ?? 0

            // Check if compression actually reduced size (no-regression behavior)
            if compressedSize < originalSize {
                // Remove existing destination if it exists
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                // Move compressed file to destination
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                return CompressionStats(
                    originalSize: originalSize,
                    compressedSize: compressedSize,
                    level: level
                )
            } else {
                // No savings; copy original to destination and clean up temp
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
        } catch {
            // Clean up on error
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
    }

    /// Compress PNG in-place (overwrites original)
    func compressPNGInPlace(fileURL: URL, level: Int) throws -> CompressionStats {
        let fileManager = FileManager.default

        // Get original file size
        let originalSize = try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0

        // Start accessing security-scoped resource for file's parent directory
        let fileParent = fileURL.deletingLastPathComponent()
        let fileAccessing = fileParent.startAccessingSecurityScopedResource()
        defer {
            if fileAccessing {
                fileParent.stopAccessingSecurityScopedResource()
            }
        }

        // Copy file to temp directory for processing (oxipng subprocess has access)
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent("oxipng_work_\(UUID().uuidString).png")
        try fileManager.copyItem(at: fileURL, to: tempURL)

        // Build oxipng arguments to work on temp file
        let arguments = buildOxipngArguments(level: level, filePath: tempURL.path)

        do {
            // Run oxipng on the temp file
            let result = try processRunner.runBundledTool("oxipng", arguments: arguments)

            guard result.succeeded else {
                // Clean up temp file on failure
                try? fileManager.removeItem(at: tempURL)
                throw OxipngError.compressionFailed(result.stderr.isEmpty ? result.stdout : result.stderr)
            }

            // Get compressed size
            let compressedSize = try fileManager.attributesOfItem(atPath: tempURL.path)[.size] as? Int ?? 0

            // Check if compression actually helped
            if compressedSize < originalSize {
                // Success! Replace original with compressed version
                try fileManager.removeItem(at: fileURL)
                try fileManager.moveItem(at: tempURL, to: fileURL)
                return CompressionStats(
                    originalSize: originalSize,
                    compressedSize: compressedSize,
                    level: level
                )
            } else {
                // No savings; keep original and remove temp
                try? fileManager.removeItem(at: tempURL)
                return CompressionStats(
                    originalSize: originalSize,
                    compressedSize: originalSize,
                    level: level
                )
            }
        } catch {
            // Clean up temp file on error
            try? fileManager.removeItem(at: tempURL)
            throw error
        }
    }

    /// Build oxipng command-line arguments based on compression level
    /// Progressive optimization strategy:
    /// - Level 0: Fastest, minimal optimization
    /// - Level 1-2: Light optimization
    /// - Level 3-4: Medium optimization + strip safe metadata
    /// - Level 5: Heavy optimization + strip all metadata
    /// - Level 6: Maximum (Zopfli + strip all)
    private func buildOxipngArguments(level: Int, filePath: String) -> [String] {
        var args: [String] = []

        // Set optimization level
        args.append("-o")
        args.append("\(level)")

        // Add progressive features based on level
        switch level {
        case 0, 1, 2:
            // No additional flags for fastest levels
            break
        case 3, 4:
            // Strip safe metadata (non-essential)
            args.append("--strip")
            args.append("safe")
        case 5:
            // Strip all metadata
            args.append("--strip")
            args.append("all")
        case 6:
            // Maximum compression: strip all + Zopfli
            args.append("--strip")
            args.append("all")
            args.append("-Z") // Enable Zopfli compression (slowest, best results)
        default:
            break
        }

        // Add file path
        args.append(filePath)

        return args
    }
}
