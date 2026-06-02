import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Backgrounds
    static let bgPrimary     = Color(hex: "#0F1112")
    static let bgElevated    = Color(hex: "#191B1D")
    static let bgCard        = Color(hex: "#202326")
    static let bgInset       = Color(hex: "#2A2D30")

    // Foregrounds
    static let fgPrimary     = Color(hex: "#F4F8F7")
    static let fgDim         = Color(hex: "#F4F8F7").opacity(0.66)
    static let fgFaint       = Color(hex: "#F4F8F7").opacity(0.40)
    static let fgGhost       = Color(hex: "#F4F8F7").opacity(0.18)

    // Strokes
    static let strokeDefault = Color(hex: "#F4F8F7").opacity(0.08)
    static let strokeStrong  = Color(hex: "#F4F8F7").opacity(0.14)

    // Accents
    static let sage          = Color(hex: "#BCE7B5")
    static let sageDim       = Color(hex: "#A7D7A2").opacity(0.18)
    static let amber         = Color(hex: "#73D5FF")
    static let amberDim      = Color(hex: "#64C7F2").opacity(0.18)
    static let clay          = Color(hex: "#55E4C4")
    static let clayDim       = Color(hex: "#37D4B0").opacity(0.18)
    static let ink           = Color(hex: "#9FCEEE")
    static let inkDim        = Color(hex: "#8FB7D8").opacity(0.18)

    // Risk
    static let riskLow       = Color(hex: "#BCE7B5")
    static let riskMed       = Color(hex: "#73D5FF")
    static let riskHigh      = Color(hex: "#55E4C4")

    // Dark text on light bg (for sage buttons etc.)
    static let darkText      = Color(hex: "#061317")

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
        ZStack {
            tickMarks

            Circle()
                .stroke(Color.bgInset, lineWidth: strokeWidth)
                .frame(width: size - strokeWidth, height: size - strokeWidth)

            Circle()
                .trim(from: 0, to: pct)
                .stroke(ringColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .frame(width: size - strokeWidth, height: size - strokeWidth)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: score)

            centerLabel
        }
        .frame(width: size, height: size)
    }

    private var tickMarks: some View {
        ForEach(0..<24, id: \.self) { index in
            RiskRingTickMark(index: index, size: size, strokeWidth: strokeWidth)
        }
    }

    private var centerLabel: some View {
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
}

private struct RiskRingTickMark: View {
    let index: Int
    let size: CGFloat
    let strokeWidth: CGFloat

    var body: some View {
        Path { path in
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }
        .stroke(Color.fgGhost, lineWidth: 1)
    }

    private var angle: CGFloat {
        CGFloat(index) / 24.0 * 2.0 * .pi - .pi / 2.0
    }

    private var innerRadius: CGFloat {
        let radius = (size - strokeWidth) / 2.0
        return radius + strokeWidth / 2.0 + 4.0
    }

    private var outerRadius: CGFloat {
        let radius = (size - strokeWidth) / 2.0
        return radius + strokeWidth / 2.0 + 9.0
    }

    private var startPoint: CGPoint {
        CGPoint(
            x: size / 2.0 + cos(angle) * innerRadius,
            y: size / 2.0 + sin(angle) * innerRadius
        )
    }

    private var endPoint: CGPoint {
        CGPoint(
            x: size / 2.0 + cos(angle) * outerRadius,
            y: size / 2.0 + sin(angle) * outerRadius
        )
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
        case "note":     return "note.text"
        case "shield":   return "checkmark.shield"
        case "lock":     return "lock"
        case "cloud":    return "icloud"
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
        .buttonStyle(PressableButtonStyle(scale: 0.97))
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
                .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isActive)
        }
        .buttonStyle(PressableButtonStyle())
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
                if let suffix = titleItalicSuffix {
                    (Text(title).font(DS.serif(36)).foregroundColor(.fgPrimary)
                    + Text(suffix).font(DS.serif(36, italic: true)).foregroundColor(.fgPrimary))
                } else {
                    Text(title).font(DS.serif(36)).foregroundColor(.fgPrimary)
                }
            }
            Spacer()
            if let right = rightContent {
                right
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
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

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

// MARK: - Appear Animation

struct AppearModifier: ViewModifier {
    let delay: Double
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .onAppear {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.82).delay(delay)) {
                    visible = true
                }
            }
            .onDisappear { visible = false }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearModifier(delay: delay))
    }
}

// MARK: - Page Transition

extension AnyTransition {
    static var pageFade: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 12)),
            removal: .opacity
        )
    }
}
