import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct PNGtoICOView: View {
    @State private var selectedResolutions: Set<Int> = [16, 32, 48, 64, 128, 256]
    @State private var outputFolder: URL? = nil
    @State private var log: [String] = []
    @State private var isProcessing = false

    let gradient = LinearGradient.vibrantBlue

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(gradient)

                    Text("PNG → ICO Converter")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Convert PNG images to ICO format for game engines like Godot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Controls Card
                VStack(spacing: 20) {
                    // Resolution Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "square.grid.3x3")
                                .foregroundStyle(gradient)
                            Text("Resolutions to Include")
                                .font(.headline)
                            Spacer()
                            Button(action: toggleAllResolutions) {
                                Text(selectedResolutions.count == IconConverter.availableResolutions.count ? "Deselect All" : "Select All")
                                    .font(.caption)
                                    .foregroundColor(.appBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // Resolution Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(IconConverter.availableResolutions, id: \.self) { resolution in
                                ResolutionToggle(
                                    resolution: resolution,
                                    isSelected: selectedResolutions.contains(resolution)
                                ) {
                                    toggleResolution(resolution)
                                }
                            }
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
                }
                .glassCard()
                .padding(.horizontal, 24)

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

    private func toggleAllResolutions() {
        if selectedResolutions.count == IconConverter.availableResolutions.count {
            selectedResolutions.removeAll()
        } else {
            selectedResolutions = Set(IconConverter.availableResolutions)
        }
    }

    private func toggleResolution(_ resolution: Int) {
        if selectedResolutions.contains(resolution) {
            selectedResolutions.remove(resolution)
        } else {
            selectedResolutions.insert(resolution)
        }
    }

    private func chooseOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            outputFolder = panel.url
        }
    }

    private func processPNGs(_ urls: [URL]) {
        guard !urls.isEmpty else {
            print("DEBUG: No URLs provided")
            return
        }

        print("DEBUG: Processing \(urls.count) files: \(urls.map { $0.lastPathComponent })")

        // Validate resolutions
        guard !selectedResolutions.isEmpty else {
            Task { @MainActor in
                withAnimation {
                    log.append("✗ No resolutions selected. Please select at least one resolution.")
                }
            }
            return
        }

        Task { @MainActor in
            withAnimation {
                isProcessing = true
            }
            let resolutionsText = selectedResolutions.sorted().map { "\($0)px" }.joined(separator: ", ")
            log.append("Converting \(urls.count) file(s) with resolutions: \(resolutionsText)…")
            if outputFolder == nil {
                log.append("ℹ️ You'll be prompted to choose where to save each file.")
            }
        }

        Task {
            let converter = IconConverter()
            let sortedResolutions = Array(selectedResolutions).sorted()

            print("DEBUG: Starting conversion with resolutions: \(sortedResolutions)")

            for url in urls {
                do {
                    print("DEBUG: Converting \(url.lastPathComponent)")

                    // Start accessing security-scoped resource
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    let base = url.deletingPathExtension().lastPathComponent
                    let destinationDir: URL
                    let outURL: URL

                    if let folder = outputFolder {
                        // User has selected an output folder
                        destinationDir = folder
                        outURL = destinationDir.appendingPathComponent("\(base).ico")
                    } else {
                        // No output folder - prompt user to save
                        let saveURL = await MainActor.run {
                            let panel = NSSavePanel()
                            panel.nameFieldStringValue = "\(base).ico"
                            panel.message = "Choose where to save the ICO file"
                            panel.allowedContentTypes = [UTType(filenameExtension: "ico") ?? .data]
                            return panel.runModal() == .OK ? panel.url : nil
                        }

                        guard let saveURL = saveURL else {
                            print("DEBUG: User cancelled save for \(url.lastPathComponent)")
                            await MainActor.run {
                                withAnimation {
                                    log.append("⊘ \(url.lastPathComponent) cancelled")
                                }
                            }
                            continue
                        }

                        outURL = saveURL
                    }

                    print("DEBUG: Output will be: \(outURL.path)")

                    // Convert PNG to ICO
                    try converter.convertPNGtoICO(
                        sourceURL: url,
                        destinationURL: outURL,
                        resolutions: sortedResolutions
                    )

                    print("DEBUG: Conversion successful for \(url.lastPathComponent)")

                    await MainActor.run {
                        withAnimation {
                            log.append("✓ \(url.lastPathComponent) → \(outURL.lastPathComponent)")
                        }
                    }

                    // Small delay for visual effect
                    try? await Task.sleep(nanoseconds: 100_000_000)
                } catch {
                    print("DEBUG: Conversion failed for \(url.lastPathComponent): \(error)")
                    await MainActor.run {
                        withAnimation {
                            let nsError = error as NSError
                            if nsError.domain == NSCocoaErrorDomain && nsError.code == 513 {
                                // Permission error - suggest using output folder
                                log.append("✗ \(url.lastPathComponent) failed: Permission denied. Please select an output folder.")
                            } else {
                                log.append("✗ \(url.lastPathComponent) failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }

            await MainActor.run {
                withAnimation {
                    log.append("Done. Converted \(urls.count) file(s).")
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Resolution Toggle
struct ResolutionToggle: View {
    let resolution: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .appBlue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(resolution)×\(resolution)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .primary : .secondary)
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.appBlue.opacity(0.1) : Color.secondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.appBlue : Color.secondary.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}
