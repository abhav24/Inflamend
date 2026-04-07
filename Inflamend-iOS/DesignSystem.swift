import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let brandPrimary   = Color(red: 0.388, green: 0.400, blue: 0.945)
    static let brandSecondary = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let brandSuccess   = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let brandWarning   = Color(red: 0.961, green: 0.620, blue: 0.043)
    static let brandDanger    = Color(red: 0.937, green: 0.267, blue: 0.267)
}

extension ShapeStyle where Self == Color {
    static var brandPrimary:   Color { .init(red: 0.388, green: 0.400, blue: 0.945) }
    static var brandSecondary: Color { .init(red: 0.545, green: 0.361, blue: 0.965) }
    static var brandSuccess:   Color { .init(red: 0.063, green: 0.725, blue: 0.506) }
    static var brandWarning:   Color { .init(red: 0.961, green: 0.620, blue: 0.043) }
    static var brandDanger:    Color { .init(red: 0.937, green: 0.267, blue: 0.267) }
}

// MARK: - Gradients

struct AppGradient {
    static var brand: LinearGradient {
        LinearGradient(colors: [.brandPrimary, .brandSecondary],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var success: LinearGradient {
        LinearGradient(colors: [.brandSuccess, Color(red: 0.020, green: 0.588, blue: 0.400)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var sunset: LinearGradient {
        LinearGradient(colors: [Color(red: 0.988, green: 0.565, blue: 0.243),
                                Color(red: 0.937, green: 0.267, blue: 0.267)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var ocean: LinearGradient {
        LinearGradient(colors: [Color(red: 0.235, green: 0.741, blue: 0.980),
                                Color(red: 0.388, green: 0.400, blue: 0.945)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var mint: LinearGradient {
        LinearGradient(colors: [Color(red: 0.200, green: 0.850, blue: 0.706),
                                Color(red: 0.063, green: 0.725, blue: 0.506)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var gradient: LinearGradient = AppGradient.brand
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false,
         gradient: LinearGradient = AppGradient.brand, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.gradient = gradient
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title).fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Progress Bar

struct BrandProgressBar: View {
    var value: Double
    var color: Color = .brandPrimary
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(value, 1))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Icon Badge

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(color.opacity(0.12))
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - User Avatar

struct UserAvatarView: View {
    let name: String
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var bgColor: Color {
        let palette: [Color] = [
            .init(red: 0.388, green: 0.400, blue: 0.945),
            .init(red: 0.545, green: 0.361, blue: 0.965),
            .init(red: 0.063, green: 0.725, blue: 0.506),
            .init(red: 0.235, green: 0.510, blue: 0.960),
            .init(red: 0.960, green: 0.380, blue: 0.600),
            .init(red: 0.988, green: 0.480, blue: 0.243),
            .init(red: 0.200, green: 0.780, blue: 0.720),
        ]
        let hash = name.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }

    var body: some View {
        ZStack {
            Circle().fill(bgColor)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title).font(.title3).fontWeight(.bold)
            if let count {
                Text("\(count)")
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.brandPrimary.opacity(0.1))
                    .foregroundStyle(.brandPrimary)
                    .clipShape(Capsule())
            }
            Spacer()
            if let label = actionLabel, let action {
                Button(action: action) {
                    Text(label).font(.subheadline).foregroundStyle(.brandPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.subheadline)
                    if let sub = subtitle {
                        Text(sub).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(.medium)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .foregroundStyle(selected ? .white : .primary)
                .background(
                    Group {
                        if selected {
                            AnyView(AppGradient.brand)
                        } else {
                            AnyView(Color(.secondarySystemBackground))
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(selected ? Color.clear : Color(.separator), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
    }
}

// MARK: - Labeled Field

struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...10
    var color: Color = .brandPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: 1)
                .tint(color)
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var greeting: String {
        switch Calendar.current.component(.hour, from: self) {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var relativeLabel: String {
        if Calendar.current.isDateInToday(self)     { return "Today" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        return dateString("MMM d")
    }

    func dateString(_ format: String) -> String {
        let f = DateFormatter(); f.dateFormat = format; return f.string(from: self)
    }
}

// MARK: - Input Validator

struct InputValidator {
    static func sanitize(_ input: String, maxLength: Int) -> String {
        String(input.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxLength))
    }
    static func isValidEmail(_ value: String) -> Bool {
        value.contains("@") && value.contains(".")
    }
    static func isValidName(_ value: String) -> Bool {
        value.count >= 2 && value.count <= 50
    }
}

// MARK: - Feature Pill

struct FeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption)
            Text(label).font(.caption).fontWeight(.semibold)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .foregroundStyle(.white)
        .background(.white.opacity(0.18))
        .clipShape(Capsule())
    }
}

// MARK: - Stat Cell (Stats Strip)

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
