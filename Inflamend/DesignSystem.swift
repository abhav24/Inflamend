import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Backgrounds
    static let bgPrimary     = Color(hex: "#141210")
    static let bgElevated    = Color(hex: "#1C1A17")
    static let bgCard        = Color(hex: "#221F1B")
    static let bgInset       = Color(hex: "#2B2824")

    // Foregrounds
    static let fgPrimary     = Color(hex: "#F6F1E4")
    static let fgDim         = Color(hex: "#F6F1E4").opacity(0.62)
    static let fgFaint       = Color(hex: "#F6F1E4").opacity(0.38)
    static let fgGhost       = Color(hex: "#F6F1E4").opacity(0.18)

    // Strokes
    static let strokeDefault = Color(hex: "#F6F1E4").opacity(0.08)
    static let strokeStrong  = Color(hex: "#F6F1E4").opacity(0.14)

    // Accents
    static let sage          = Color(hex: "#A8B89A")
    static let sageDim       = Color(hex: "#A8B89A").opacity(0.18)
    static let amber         = Color(hex: "#E3A963")
    static let amberDim      = Color(hex: "#E3A963").opacity(0.18)
    static let clay          = Color(hex: "#D98466")
    static let clayDim       = Color(hex: "#D98466").opacity(0.18)
    static let ink           = Color(hex: "#8A94A2")
    static let inkDim        = Color(hex: "#8A94A2").opacity(0.18)

    // Risk
    static let riskLow       = Color(hex: "#A8B89A")
    static let riskMed       = Color(hex: "#E3A963")
    static let riskHigh      = Color(hex: "#D96A52")

    // Dark text on light bg (for sage buttons etc.)
    static let darkText      = Color(hex: "#1A1612")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography

struct DS {
    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        italic
            ? .custom("Georgia-Italic", size: size)
            : .custom("Georgia", size: size)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Courier New", size: size).weight(weight)
    }
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Label style (mono uppercase faint)

struct DSLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DS.mono(10, weight: .medium))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundColor(.fgFaint)
    }
}

extension View {
    func dsLabel() -> some View { modifier(DSLabel()) }
}

// MARK: - Card

struct CardBackground: ViewModifier {
    var padding: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.strokeDefault, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

extension View {
    func card(padding: CGFloat = 18) -> some View { modifier(CardBackground(padding: padding)) }
}

// MARK: - Risk Ring

struct RiskRing: View {
    var score: Int
    var size: CGFloat = 200
    var strokeWidth: CGFloat = 14

    private var pct: Double { min(100, max(0, Double(score))) / 100.0 }
    private var tier: RiskTier {
        score < 30 ? .low : score < 60 ? .med : .high
    }

    enum RiskTier { case low, med, high }

    private var ringColor: Color {
        switch tier {
        case .low:  return .riskLow
        case .med:  return .riskMed
        case .high: return .riskHigh
        }
    }
    private var tierLabel: String {
        switch tier {
        case .low:  return "Low"
        case .med:  return "Medium"
        case .high: return "High"
        }
    }

    var body: some View {
        let r = (size - strokeWidth) / 2
        let circumference = 2 * Double.pi * r

        ZStack {
            // Tick marks
            ForEach(0..<24, id: \.self) { i in
                let angle = Double(i) / 24.0 * 2 * Double.pi - Double.pi / 2
                let innerR = r + strokeWidth / 2 + 4
                let outerR = r + strokeWidth / 2 + 9
                Path { path in
                    path.move(to: CGPoint(
                        x: size / 2 + cos(angle) * innerR,
                        y: size / 2 + sin(angle) * innerR))
                    path.addLine(to: CGPoint(
                        x: size / 2 + cos(angle) * outerR,
                        y: size / 2 + sin(angle) * outerR))
                }
                .stroke(Color.fgGhost, lineWidth: 1)
            }

            // Background ring
            Circle()
                .stroke(Color.bgInset, lineWidth: strokeWidth)
                .frame(width: size - strokeWidth, height: size - strokeWidth)

            // Foreground arc
            Circle()
                .trim(from: 0, to: pct)
                .stroke(ringColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .frame(width: size - strokeWidth, height: size - strokeWidth)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: score)

            // Center text
            VStack(spacing: 2) {
                Text("\(tierLabel) risk")
                    .font(DS.mono(10, weight: .medium))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(ringColor)
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(score)")
                        .font(DS.serif(46))
                        .foregroundColor(.fgPrimary)
                    Text("/100")
                        .font(DS.mono(13))
                        .foregroundColor(.fgFaint)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mini Ring

struct MiniRing: View {
    var value: Double = 0.6
    var color: Color = .sage
    var size: CGFloat = 38
    let sw: CGFloat = 4

    var body: some View {
        let r = (size - sw) / 2
        ZStack {
            Circle().stroke(Color.bgInset, lineWidth: sw)
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: sw, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Chip

struct DSChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(DS.mono(11))
            .tracking(0.4)
            .foregroundColor(.fgDim)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.bgInset)
            .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.strokeDefault, lineWidth: 0.5))
            .clipShape(Capsule())
    }
}

// MARK: - Tag

struct DSTag: View {
    enum Variant { case sage, amber, clay }
    let text: String
    let variant: Variant
    var body: some View {
        let (bg, fg): (Color, Color) = {
            switch variant {
            case .sage:  return (.sageDim, .sage)
            case .amber: return (.amberDim, .amber)
            case .clay:  return (.clayDim, .clay)
            }
        }()
        Text(text)
            .font(DS.mono(10))
            .tracking(0.4)
            .textCase(.uppercase)
            .foregroundColor(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Icon

struct AppIcon: View {
    let name: String
    var size: CGFloat = 22
    var color: Color = .fgPrimary

    private var systemName: String {
        switch name {
        case "home":     return "house"
        case "plus":     return "plus"
        case "chart":    return "chart.bar"
        case "chat":     return "bubble.left"
        case "user":     return "person"
        case "bell":     return "bell"
        case "leaf":     return "leaf"
        case "flame":    return "flame"
        case "droplet":  return "drop"
        case "moon":     return "moon"
        case "pill":     return "pills"
        case "fork":     return "fork.knife"
        case "heart":    return "heart"
        case "check":    return "checkmark"
        case "close":    return "xmark"
        case "chevron":  return "chevron.right"
        case "mic":      return "mic"
        case "send":     return "paperplane"
        case "sparkle":  return "sparkles"
        case "clock":    return "clock"
        case "calendar": return "calendar"
        case "activity": return "waveform.path.ecg"
        case "dna":      return "staroflife"
        case "settings": return "gear"
        case "book":     return "book"
        case "download": return "arrow.down.circle"
        case "logout":   return "rectangle.portrait.and.arrow.right"
        default:         return "circle"
        }
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.72, weight: .light))
            .foregroundColor(color)
            .frame(width: size, height: size)
    }
}

// MARK: - IconBadge (colored circle bg)

struct IconBadge: View {
    let name: String
    var size: CGFloat = 36
    var iconSize: CGFloat = 16
    var color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.13))
                .frame(width: size, height: size)
            AppIcon(name: name, size: iconSize, color: color)
        }
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.sans(15, weight: .medium))
                .tracking(-0.1)
                .foregroundColor(.darkText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.sage)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ghost Button

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.sans(15, weight: .medium))
                .foregroundColor(.fgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.bgInset)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Pill

struct LogPill: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.sans(13, weight: .medium))
                .foregroundColor(isActive ? .bgPrimary : .fgDim)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isActive ? Color.fgPrimary : Color.bgInset)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slider style

struct DSSliderStyle: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...10
    var color: Color = .sage

    var body: some View {
        Slider(value: $value, in: range)
            .tint(color)
    }
}

// MARK: - Toast

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(DS.sans(14, weight: .medium))
            .foregroundColor(.darkText)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.sage)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Screen header

struct ScreenHeader: View {
    var subtitle: String? = nil
    let title: String
    var titleItalicSuffix: String? = nil
    var rightContent: AnyView? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                if let sub = subtitle {
                    Text(sub)
                        .dsLabel()
                        .padding(.bottom, 2)
                }
                HStack(spacing: 0) {
                    Text(title)
                        .font(DS.serif(36))
                        .foregroundColor(.fgPrimary)
                    if let suffix = titleItalicSuffix {
                        Text(suffix)
                            .font(DS.serif(36, italic: true))
                            .foregroundColor(.fgPrimary)
                    }
                }
            }
            Spacer()
            if let right = rightContent {
                right
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }
}

// MARK: - Divider

struct DSDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.strokeDefault)
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }
}

// MARK: - Sheet Handle

struct SheetHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 999)
            .fill(Color.fgGhost)
            .frame(width: 40, height: 5)
    }
}
