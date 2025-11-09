import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct PNGCompressionView: View {
    @State private var compressionLevel: Int = 3 // Default: balanced (0-6)
    @State private var replaceInPlace: Bool = false
    @State private var outputFolder: URL? = nil
    @State private var log: [String] = []
    @State private var isProcessing = false
    @State private var totalOriginalSize: Int = 0
    @State private var totalCompressedSize: Int = 0

    let gradient = LinearGradient.vibrantGreen

    var totalSavingsPercentage: Double {
        guard totalOriginalSize > 0 else { return 0.0 }
        let saved = totalOriginalSize - totalCompressedSize
        return Double(saved) / Double(totalOriginalSize) * 100.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(gradient)

                    Text("PNG Compression")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Optimize PNG files with lossless compression")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Controls Card
                VStack(spacing: 20) {
                    // Compression Level Slider
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundStyle(gradient)
                            Text("Compression Level")
                                .font(.headline)
                            Spacer()
                            Text(compressionLevelName(compressionLevel))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.appGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.appGreen.opacity(0.15))
                                )
                        }

                        HStack(spacing: 12) {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Slider(value: Binding(
                                get: { Double(compressionLevel) },
                                set: { compressionLevel = Int($0.rounded()) }
                            ), in: 0...6, step: 1)
                            .accentColor(.appGreen)

                            Text("6")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 8) {
                            Text("←")
                                .font(.caption2)
                            Text("Fastest")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Best Compression")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("→")
                                .font(.caption2)
                        }
                    }

                    Divider()

                    // Replace In-Place Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $replaceInPlace) {
                            HStack(spacing: 8) {
                                Image(systemName: replaceInPlace ? "arrow.triangle.2.circlepath.circle.fill" : "folder.badge.plus")
                                    .foregroundStyle(gradient)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(replaceInPlace ? "Replace Original Files" : "Save to Output Folder")
                                        .font(.headline)
                                    Text(replaceInPlace ? "⚠️ Original files will be overwritten" : "Keep originals, save compressed copies")
                                        .font(.caption)
                                        .foregroundColor(replaceInPlace ? .orange : .secondary)
                                }
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .appGreen))
                    }

                    // Output Folder (shown only when NOT replacing in-place)
                    if !replaceInPlace {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(gradient)
                                Text("Output Folder")
                                    .font(.headline)
                                Spacer()
                            }

                            Button(action: chooseOutputFolder) {
                                HStack {
                                    Image(systemName: outputFolder == nil ? "folder.badge.plus" : "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(outputFolder == nil ? gradient : LinearGradient(colors: [.green], startPoint: .leading, endPoint: .trailing))
                                    Text(outputFolder?.path ?? "Use same folder as source")
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(gradient.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    }
                }
                .glassCard()
                .padding(.horizontal, 24)
                .animation(.spring(response: 0.3), value: replaceInPlace)

                // Drop Zone
                DropTargetView(
                    accepts: [.png],
                    gradient: gradient,
                    onFilesDropped: processPNGs
                ) {
                    Text("Drop **PNG** files here")
                }
                .frame(height: 200)
                .padding(.horizontal, 24)

                // Statistics Card (shown when files have been processed)
                if totalOriginalSize > 0 {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(gradient)
                            Text("Compression Statistics")
                                .font(.headline)
                            Spacer()
                        }

                        HStack(spacing: 20) {
                            // Original Size
                            StatBox(
                                title: "Original",
                                value: CompressionStats.formatBytes(totalOriginalSize),
                                icon: "arrow.up.circle.fill",
                                color: .red
                            )

                            // Compressed Size
                            StatBox(
                                title: "Compressed",
                                value: CompressionStats.formatBytes(totalCompressedSize),
                                icon: "arrow.down.circle.fill",
                                color: .appGreen
                            )

                            // Savings
                            StatBox(
                                title: "Saved",
                                value: String(format: "%.1f%%", totalSavingsPercentage),
                                icon: "sparkles",
                                color: .appPurple
                            )
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                // Log Viewer
                if !log.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .foregroundStyle(gradient)
                            Text("Compression Log")
                                .font(.headline)
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            Button(action: clearLog) {
                                Image(systemName: "trash")
                                    .foregroundColor(.secondary)
                            }
                            .iconButton(color: .red)
                        }

                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(log.indices, id: \.self) { i in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: logIcon(for: log[i]))
                                            .foregroundColor(logColor(for: log[i]))
                                            .frame(width: 16)
                                        Text(log[i])
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(logColor(for: log[i]).opacity(0.1))
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 200)
                    }
                    .glassCard()
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                Spacer(minLength: 24)
            }
        }
    }

    // MARK: - Helpers

    private func compressionLevelName(_ level: Int) -> String {
        switch level {
        case 0: return "Fastest"
        case 1: return "Fast"
        case 2: return "Normal"
        case 3: return "Balanced"
        case 4: return "Good"
        case 5: return "Better"
        case 6: return "Best"
        default: return "Level \(level)"
        }
    }

    private func logIcon(for message: String) -> String {
        if message.contains("✓") { return "checkmark.circle.fill" }
        if message.contains("✗") { return "xmark.circle.fill" }
        if message.contains("Compressing") || message.contains("Done") { return "info.circle.fill" }
        if message.contains("💾") { return "arrow.down.circle.fill" }
        return "circle.fill"
    }

    private func logColor(for message: String) -> Color {
        if message.contains("✓") { return .green }
        if message.contains("✗") { return .red }
        if message.contains("Compressing") { return .appOrange }
        if message.contains("Done") { return .appBlue }
        if message.contains("💾") { return .appGreen }
        return .secondary
    }

    // MARK: - Actions

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            outputFolder = panel.url
        }
    }

    private func clearLog() {
        withAnimation {
            log.removeAll()
            totalOriginalSize = 0
            totalCompressedSize = 0
        }
    }

    private func processPNGs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        Task { @MainActor in
            withAnimation {
                isProcessing = true
            }
            let levelName = compressionLevelName(compressionLevel)
            log.append("Compressing \(urls.count) file(s) with level \(compressionLevel) (\(levelName))…")
            if replaceInPlace {
                log.append("⚠️ Replacing original files in-place")
            } else if outputFolder == nil {
                log.append("ℹ️ You'll be prompted to choose where to save each file.")
            }
        }

        Task {
            let compressor = PNGCompressor()
            var sessionOriginalSize = 0
            var sessionCompressedSize = 0

            for url in urls {
                do {
                    // Start accessing security-scoped resource
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    let stats: CompressionStats

                    if replaceInPlace {
                        // Replace original file
                        stats = try compressor.compressPNGInPlace(fileURL: url, level: compressionLevel)

                        await MainActor.run {
                            withAnimation {
                                let sizeBefore = CompressionStats.formatBytes(stats.originalSize)
                                let sizeAfter = CompressionStats.formatBytes(stats.compressedSize)
                                let savings = String(format: "%.1f%%", stats.savingsPercentage)
                                log.append("✓ \(url.lastPathComponent): \(sizeBefore) → \(sizeAfter) (saved \(savings))")
                            }
                        }
                    } else {
                        // Save to output folder or prompt user to save
                        let base = url.deletingPathExtension().lastPathComponent
                        let outURL: URL

                        if let folder = outputFolder {
                            // User has selected an output folder
                            outURL = folder.appendingPathComponent("\(base)_compressed.png")
                        } else {
                            // No output folder - prompt user to save
                            let saveURL = await MainActor.run {
                                let panel = NSSavePanel()
                                panel.nameFieldStringValue = "\(base)_compressed.png"
                                panel.message = "Choose where to save the compressed PNG file"
                                panel.allowedContentTypes = [.png]
                                return panel.runModal() == .OK ? panel.url : nil
                            }

                            guard let saveURL = saveURL else {
                                // User cancelled save
                                await MainActor.run {
                                    withAnimation {
                                        log.append("⊘ \(url.lastPathComponent) cancelled")
                                    }
                                }
                                continue
                            }

                            outURL = saveURL
                        }

                        stats = try compressor.compressPNG(
                            sourceURL: url,
                            destinationURL: outURL,
                            level: compressionLevel
                        )

                        await MainActor.run {
                            withAnimation {
                                let sizeBefore = CompressionStats.formatBytes(stats.originalSize)
                                let sizeAfter = CompressionStats.formatBytes(stats.compressedSize)
                                let savings = String(format: "%.1f%%", stats.savingsPercentage)
                                log.append("✓ \(url.lastPathComponent) → \(outURL.lastPathComponent)")
                                log.append("   💾 \(sizeBefore) → \(sizeAfter) (saved \(savings))")
                            }
                        }
                    }

                    sessionOriginalSize += stats.originalSize
                    sessionCompressedSize += stats.compressedSize

                    // Small delay for visual effect
                    try? await Task.sleep(nanoseconds: 100_000_000)

                } catch {
                    await MainActor.run {
                        withAnimation {
                            log.append("✗ \(url.lastPathComponent) failed: \(error.localizedDescription)")
                        }
                    }
                }
            }

            await MainActor.run {
                withAnimation {
                    totalOriginalSize += sessionOriginalSize
                    totalCompressedSize += sessionCompressedSize

                    let totalSaved = CompressionStats.formatBytes(sessionOriginalSize - sessionCompressedSize)
                    let totalSavedPercent = sessionOriginalSize > 0
                        ? String(format: "%.1f%%", Double(sessionOriginalSize - sessionCompressedSize) / Double(sessionOriginalSize) * 100.0)
                        : "0%"

                    log.append("Done. Total saved: \(totalSaved) (\(totalSavedPercent))")
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Stat Box Component

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
