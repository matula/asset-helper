import SwiftUI
import UniformTypeIdentifiers
import AppKit

extension UTType {
    /// Works on macOS 10.15+ (falls back to the public identifier if needed)
    static var svgCompat: UTType {
        if #available(macOS 11.0, *) {
            return UTType.svg          // not optional on macOS 11+
        } else {
            // Fallback for older SDKs
            return UTType("public.svg-image") ?? .data
        }
    }

    /// Handy helper for .ico when you need it
    static var icoCompat: UTType {
        if #available(macOS 11.0, *) {
            return UTType(filenameExtension: "ico") ?? .data
        } else {
            return UTType("com.microsoft.ico") ?? .data
        }
    }
}

/// A reusable drag-and-drop target with a click-to-browse fallback.
struct DropTargetView<Content: View>: View {
    var accepts: [UTType]
    var gradient: LinearGradient = .vibrantPurple
    var onFilesDropped: ([URL]) -> Void
    @ViewBuilder var content: () -> Content

    @State private var isTargeted = false
    @State private var isHovered = false
    @State private var pulseAnimation = false
    @State private var rotation: Double = 0

    private var borderStroke: some View {
        Group {
            if isTargeted {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(AngularGradient.rotating, lineWidth: 4)
                    .rotationEffect(Angle(degrees: rotation))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(gradient, lineWidth: 3)
            }
        }
    }

    private var backgroundFill: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                gradient.opacity(isTargeted ? 0.15 : (isHovered ? 0.08 : 0.05))
            )
    }

    var body: some View {
        ZStack {
            borderStroke
                .background(backgroundFill)
                .shadow(
                    color: Color.appPurple.opacity(isTargeted ? 0.4 : 0.2),
                    radius: isTargeted ? 20 : 10,
                    y: isTargeted ? 10 : 5
                )

            VStack(spacing: 16) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0.5 : 1.0)

                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "square.and.arrow.down.on.square")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(gradient)
                        .symbolEffect(.bounce, value: isTargeted)
                }

                // Content
                content()
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(gradient)

                // Hint text
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                    Text("Click to choose files or drag & drop")
                        .font(.callout)
                }
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1.0 : 0.7)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .scaleEffect(isTargeted ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
        .animation(.spring(response: 0.4), value: isHovered)
        .onTapGesture {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = accepts
            if panel.runModal() == .OK {
                onFilesDropped(panel.urls)
            }
        }
        .onHover { inside in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = inside
            }
            if inside {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        .onDrop(of: [UTType.fileURL.identifier] + accepts.map(\.identifier), isTargeted: $isTargeted) { providers in
            print("DEBUG DropTarget: Received \(providers.count) providers")

            Task {
                var urls: [URL] = []

                for provider in providers {
                    print("DEBUG DropTarget: Provider registered types: \(provider.registeredTypeIdentifiers)")
                    print("DEBUG DropTarget: Has fileURL? \(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))")
                    print("DEBUG DropTarget: Has public.file-url? \(provider.hasItemConformingToTypeIdentifier("public.file-url"))")

                    // Try multiple approaches to get the file URL
                    var foundURL: URL? = nil

                    // Approach 1: Try fileURL type
                    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                        do {
                            let item = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil)
                            print("DEBUG DropTarget: Loaded fileURL item of type: \(type(of: item))")

                            if let url = item as? URL {
                                print("DEBUG DropTarget: Got URL from fileURL: \(url.path)")
                                foundURL = url
                            }
                        } catch {
                            print("DEBUG DropTarget: Error loading fileURL: \(error)")
                        }
                    }

                    // Approach 2: Try public.file-url
                    if foundURL == nil && provider.hasItemConformingToTypeIdentifier("public.file-url") {
                        do {
                            let item = try await provider.loadItem(forTypeIdentifier: "public.file-url", options: nil)
                            print("DEBUG DropTarget: Loaded public.file-url item of type: \(type(of: item))")

                            if let url = item as? URL {
                                print("DEBUG DropTarget: Got URL from public.file-url: \(url.path)")
                                foundURL = url
                            }
                        } catch {
                            print("DEBUG DropTarget: Error loading public.file-url: \(error)")
                        }
                    }

                    // Approach 3: Try each accepted content type
                    if foundURL == nil {
                        for acceptedType in accepts {
                            if provider.hasItemConformingToTypeIdentifier(acceptedType.identifier) {
                                do {
                                    let item = try await provider.loadItem(forTypeIdentifier: acceptedType.identifier, options: nil)
                                    print("DEBUG DropTarget: Loaded \(acceptedType.identifier) item of type: \(type(of: item))")

                                    if let url = item as? URL {
                                        print("DEBUG DropTarget: Got URL from \(acceptedType.identifier): \(url.path)")
                                        foundURL = url
                                        break
                                    } else if let data = item as? Data {
                                        if let url = URL(dataRepresentation: data, relativeTo: nil) {
                                            print("DEBUG DropTarget: Got URL from data: \(url.path)")
                                            foundURL = url
                                            break
                                        }
                                        print("DEBUG DropTarget: Got \(data.count) bytes of data but couldn't convert to URL")
                                    }
                                } catch {
                                    print("DEBUG DropTarget: Error loading \(acceptedType.identifier): \(error)")
                                }
                            }
                        }
                    }

                    if let url = foundURL {
                        urls.append(url)
                    } else {
                        print("DEBUG DropTarget: Failed to extract URL from provider")
                    }
                }

                print("DEBUG DropTarget: Extracted \(urls.count) URLs")

                await MainActor.run {
                    onFilesDropped(urls)
                }
            }
            return true
        }
        .onChange(of: isTargeted) { oldValue, newValue in
            if newValue {
                // Start pulse animation when targeted
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
                // Start border rotation
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                pulseAnimation = false
                rotation = 0
            }
        }
    }
}

