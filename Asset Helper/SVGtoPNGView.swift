import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct SVGtoPNGView: View {
    @State private var scalePercent: Double = 100
    @State private var outputFolder: URL? = nil
    @State private var log: [String] = []
    @State private var isProcessing = false

    let gradient = LinearGradient(colors: [.appPink, .appOrange], startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(gradient)

                    Text("SVG → PNG Converter")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Convert vector SVGs to high-quality PNG images")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // Controls Card
                VStack(spacing: 20) {
                    // Scale Control
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(gradient)
                            Text("Scale")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(scalePercent))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(gradient)
                                .frame(minWidth: 60, alignment: .trailing)
                        }

                        // Custom styled slider
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 8)

                            // Gradient progress
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(gradient)
                                    .frame(width: geometry.size.width * CGFloat((scalePercent - 10) / 990), height: 8)
                            }
                            .frame(height: 8)

                            // Slider overlay
                            Slider(value: $scalePercent, in: 10...1000, step: 10)
                                .labelsHidden()
                        }
                    }

                    Divider()

                    // Output Folder
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
                                Image(systemName: outputFolder == nil ? "folder.badge.plus" : "folder.fill.badge.checkmark")
                                    .font(.title3)
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
                }
                .glassCard()
                .padding(.horizontal, 24)

                // Drop Zone
                DropTargetView(
                    accepts: [UTType.svgCompat],
                    gradient: gradient,
                    onFilesDropped: processSVGs
                ) {
                    Text("Drop **SVG** files here")
                }
                .frame(height: 200)
                .padding(.horizontal, 24)

                // Log Viewer
                if !log.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .foregroundStyle(gradient)
                            Text("Conversion Log")
                                .font(.headline)
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            Button(action: { log.removeAll() }) {
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

    // MARK: - Log Helpers
    private func logIcon(for message: String) -> String {
        if message.contains("✓") { return "checkmark.circle.fill" }
        if message.contains("✗") { return "xmark.circle.fill" }
        if message.contains("Converting") || message.contains("Done") { return "info.circle.fill" }
        return "circle.fill"
    }

    private func logColor(for message: String) -> Color {
        if message.contains("✓") { return .green }
        if message.contains("✗") { return .red }
        if message.contains("Converting") { return .appOrange }
        if message.contains("Done") { return .appBlue }
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

    private func processSVGs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        Task { @MainActor in
            withAnimation {
                isProcessing = true
            }
            log.append("Converting \(urls.count) file(s) at \(Int(scalePercent))% scale…")
        }

        Task {
            // Placeholder conversion: copy files and pretend to convert.
            // (You'll replace this with your real renderer—resvg/WebKit—later.)
            for url in urls {
                do {
                    let destinationDir = outputFolder ?? url.deletingLastPathComponent()
                    let base = url.deletingPathExtension().lastPathComponent
                    let outURL = destinationDir.appendingPathComponent("\(base).png")

                    // --- BEGIN REAL CONVERSION HOOK ---
                    // TODO: Replace this "dummy write" with real SVG→PNG:
                    // 1) Render SVG to CGImage at requested scale
                    // 2) Write PNG with CGImageDestination
                    try Data().write(to: outURL) // creates empty file as a stub
                    // --- END REAL CONVERSION HOOK ---

                    await MainActor.run {
                        withAnimation {
                            log.append("✓ \(url.lastPathComponent) → \(outURL.lastPathComponent)")
                        }
                    }

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
                    log.append("Done.")
                    isProcessing = false
                }
            }
        }
    }
}

