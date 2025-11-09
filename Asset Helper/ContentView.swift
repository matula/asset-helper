import SwiftUI

enum ToolTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case tilesheetExtractor = "Tilesheet Extractor"
    case tilesheetCreator = "Tilesheet Creator"
    case svgToPng = "SVG → PNG"
    case pngToIco = "PNG → ICO"
    case pngCompression = "PNG Compression"
    case audioProcessing = "Audio Processing"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .tilesheetExtractor: return "square.grid.3x3"
        case .tilesheetCreator: return "square.grid.3x3.fill"
        case .svgToPng: return "photo.fill"
        case .pngToIco: return "app.fill"
        case .pngCompression: return "arrow.down.circle.fill"
        case .audioProcessing: return "waveform.circle.fill"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .home: return .rainbow
        case .tilesheetExtractor: return .vibrantPurple
        case .tilesheetCreator: return .vibrantPurple
        case .svgToPng: return LinearGradient(colors: [.appPink, .appOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pngToIco: return .vibrantBlue
        case .pngCompression: return .vibrantGreen
        case .audioProcessing: return .vibrantOrange
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: ToolTab = .home

    var body: some View {
        NavigationView {
            // Sidebar
            ZStack {
                // Background gradient (adapts to light/dark mode)
                LinearGradient(
                    colors: [
                        Color(nsColor: .controlBackgroundColor),
                        Color(nsColor: .controlBackgroundColor).opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // App header
                    VStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(LinearGradient.rainbow)
                        Text("Asset Helper")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(LinearGradient.rainbow)
                    }
                    .padding(.vertical, 24)

                    Divider()
                        .overlay(LinearGradient.rainbow.opacity(0.3))

                    // Tabs list
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(ToolTab.allCases) { tab in
                                SidebarButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTab = tab
                                    }
                                }
                            }
                        }
                        .padding(12)
                    }

                    Spacer()
                }
            }
            .frame(minWidth: 220)

            // Main content area
            ZStack {
                // Background (adapts to light/dark mode)
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor),
                        Color(nsColor: .controlBackgroundColor).opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Content with transition
                Group {
                    switch selectedTab {
                    case .home: HomeView()
                    case .tilesheetExtractor: TilesheetExtractorView()
                    case .tilesheetCreator: TilesheetCreatorView()
                    case .svgToPng: SVGtoPNGView()
                    case .pngToIco: PNGtoICOView()
                    case .pngCompression: PNGCompressionView()
                    case .audioProcessing: AudioProcessingView()
                    }
                }
                .id(selectedTab) // Force view recreation for animation
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity
                ))
            }
            .frame(minWidth: 700, minHeight: 500)
        }
    }
}

// MARK: - Sidebar Button
struct SidebarButton: View {
    let tab: ToolTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? tab.gradient : LinearGradient(colors: [.primary], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 24)

                Text(tab.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(nsColor: .selectedContentBackgroundColor) : (isHovered ? Color(nsColor: .controlBackgroundColor) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? tab.gradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing), lineWidth: isSelected ? 2 : 0)
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

// MARK: - Home View
struct HomeView: View {
    @State private var appearAnimation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(LinearGradient.rainbow)
                        .scaleEffect(appearAnimation ? 1.0 : 0.5)
                        .opacity(appearAnimation ? 1.0 : 0.0)

                    Text("Asset Helper")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(LinearGradient.rainbow)
                        .opacity(appearAnimation ? 1.0 : 0.0)

                    Text("Your all-in-one toolkit for game asset management")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimation ? 1.0 : 0.0)
                }
                .padding(.top, 40)

                // Feature Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    FeatureCard(
                        icon: "square.grid.3x3",
                        title: "Tilesheet Tools",
                        description: "Extract and create tilesheets with precision",
                        gradient: .vibrantPurple,
                        delay: 0.1
                    )

                    FeatureCard(
                        icon: "photo.fill",
                        title: "SVG → PNG",
                        description: "Convert vector graphics to high-quality rasters",
                        gradient: LinearGradient(colors: [.appPink, .appOrange], startPoint: .topLeading, endPoint: .bottomTrailing),
                        delay: 0.2
                    )

                    FeatureCard(
                        icon: "app.fill",
                        title: "Icon Creator",
                        description: "Generate ICO files for game engines",
                        gradient: .vibrantBlue,
                        delay: 0.3
                    )

                    FeatureCard(
                        icon: "arrow.down.circle.fill",
                        title: "PNG Optimization",
                        description: "Compress PNGs without quality loss",
                        gradient: .vibrantGreen,
                        delay: 0.4
                    )

                    FeatureCard(
                        icon: "waveform.circle.fill",
                        title: "Audio Processing",
                        description: "Normalize, boost, and convert audio files",
                        gradient: .vibrantOrange,
                        delay: 0.5
                    )

                    FeatureCard(
                        icon: "sparkles",
                        title: "More Coming",
                        description: "Additional tools in development",
                        gradient: LinearGradient(colors: [.appTeal, .appPurple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        delay: 0.6
                    )
                }
                .padding(.horizontal, 32)

                // Quick Start
                VStack(spacing: 16) {
                    Text("Quick Start")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 24) {
                        QuickStartItem(
                            icon: "hand.tap.fill",
                            text: "Select a tool from the sidebar"
                        )
                        QuickStartItem(
                            icon: "square.and.arrow.down.on.square",
                            text: "Drag & drop your files"
                        )
                        QuickStartItem(
                            icon: "checkmark.circle.fill",
                            text: "Get optimized assets"
                        )
                    }
                    .padding(20)
                    .glassCard()
                }
                .padding(.horizontal, 32)
                .opacity(appearAnimation ? 1.0 : 0.0)

                Spacer(minLength: 32)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let delay: Double

    @State private var isHovered = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(gradient)
            }

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(gradient.opacity(isHovered ? 0.8 : 0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 15 : 8, y: isHovered ? 8 : 4)
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .offset(y: appeared ? 0 : 30)
        .opacity(appeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                appeared = true
            }
        }
    }
}

// MARK: - Quick Start Item
struct QuickStartItem: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(LinearGradient.rainbow)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
// MARK: - Placeholder Views
struct TilesheetExtractorView: View {
    var body: some View {
        ComingSoonView(
            icon: "square.grid.3x3",
            title: "Tilesheet Extractor",
            description: "Drop in a tilesheet and slice it into individual PNG files with customizable tile sizes and spacing.",
            gradient: .vibrantPurple,
            features: [
                "Custom tile dimensions (e.g., 16×16, 32×32)",
                "Adjustable spacing between tiles",
                "Smart naming: basename_r{row}_c{col}.png",
                "Batch processing support"
            ]
        )
    }
}

struct TilesheetCreatorView: View {
    var body: some View {
        ComingSoonView(
            icon: "square.grid.3x3.fill",
            title: "Tilesheet Creator",
            description: "Combine multiple same-sized images into a single atlas with optional spacing and power-of-two dimensions.",
            gradient: .vibrantPurple,
            features: [
                "Automatic atlas packing",
                "Adjustable tile spacing",
                "Power-of-two dimension output",
                "JSON/PLIST metadata generation"
            ]
        )
    }
}

struct AudioProcessingView: View {
    var body: some View {
        ComingSoonView(
            icon: "waveform.circle.fill",
            title: "Audio Processing",
            description: "Process WAV, OGG, MP3, and FLAC files with normalization, bass boost, and silence trimming powered by FFmpeg.",
            gradient: .vibrantOrange,
            features: [
                "Normalize audio (peak or LUFS)",
                "Bass boost with EQ controls",
                "Auto-trim silence detection",
                "Export to WAV, OGG, MP3, FLAC"
            ]
        )
    }
}

// MARK: - Coming Soon View
struct ComingSoonView: View {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let features: [String]

    @State private var pulseAnimation = false
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(gradient.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .opacity(pulseAnimation ? 0.5 : 1.0)

                        Image(systemName: icon)
                            .font(.system(size: 56))
                            .foregroundStyle(gradient)
                    }

                    Text(title)
                        .font(.system(size: 36, weight: .bold))

                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)

                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(gradient)
                        Text("Planned Features")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(gradient)
                                    .font(.title3)

                                Text(features[index])
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(gradient.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .opacity(appeared ? 1.0 : 0.0)
                            .offset(x: appeared ? 0 : -20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appeared)
                        }
                    }
                }
                .padding(.horizontal, 40)

                // Coming Soon Badge
                HStack(spacing: 12) {
                    Image(systemName: "hammer.fill")
                        .font(.title2)
                    Text("Under Development")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(gradient)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                )
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

