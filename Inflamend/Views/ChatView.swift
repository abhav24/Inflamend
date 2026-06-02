import SwiftUI

struct ChatView: View {
    var appState: AppState
    @State private var input = ""
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomID

    let suggestions = [
        "Can I take Tylenol during a flare?",
        "Why does stress make my UC worse?",
        "What should I eat tonight?",
    ]

    // Pre-canned responses for offline/demo mode
    let responses: [String: String] = [
        "Can I take Tylenol during a flare?": "Acetaminophen (Tylenol) is generally considered safer than NSAIDs like ibuprofen for people with IBD. That said, always check with your GI doctor about what's right for your specific situation.",
        "Why does stress make my UC worse?": "The gut-brain axis is real — stress can directly affect gut motility and inflammation. Managing stress through sleep, gentle exercise, and mindfulness can really help alongside your treatment.",
        "What should I eat tonight?": "Based on your recent logs, softer, well-cooked foods tend to work best for you. Something like white rice with steamed chicken and carrots would be gentle on your gut tonight.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CARE · SAFETY").dsLabel()
                    (Text("Care ").font(DS.serif(36)).foregroundColor(.fgPrimary)
                    + Text("guide").font(DS.serif(36, italic: true)).foregroundColor(.fgPrimary))
                }
                Spacer()
                // AI avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.sage, .amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    AppIcon(name: "sparkle", size: 20, color: .darkText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    IconBadge(name: "shield", size: 34, iconSize: 15, color: .sage)
                    Text("Inflamend can explain general IBD topics and help prepare questions. It does not diagnose, treat, prescribe, or replace urgent care.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(2)
                }
                if let safety = appState.latestSafetyMessage {
                    Text(safety)
                        .font(DS.sans(12, weight: .medium))
                        .foregroundColor(.clay)
                        .lineSpacing(2)
                }
            }
            .padding(14)
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.strokeDefault, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // Messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(appState.chatMessages) { msg in
                            ChatBubble(message: msg)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(y: 10)),
                                    removal: .opacity
                                ))
                        }

                        if isTyping {
                            TypingIndicator()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                        }

                        // Suggestion chips (only when few messages)
                        if appState.chatMessages.count < 3 {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TRY ASKING")
                                    .dsLabel()
                                    .padding(.leading, 4)
                                    .padding(.top, 8)
                                ForEach(suggestions, id: \.self) { s in
                                    Button { send(s) } label: {
                                        HStack(spacing: 10) {
                                            AppIcon(name: "sparkle", size: 14, color: .sage)
                                            Text(s)
                                                .font(DS.sans(14))
                                                .foregroundColor(.fgPrimary)
                                                .tracking(-0.1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            AppIcon(name: "chevron", size: 14, color: .fgFaint)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Color.bgCard)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.strokeDefault, lineWidth: 0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    .buttonStyle(PressableButtonStyle(scale: 0.97))
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.top, 4)
                }
                .onChange(of: appState.chatMessages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: isTyping) { _, _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // Composer
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.bgPrimary.opacity(0), Color.bgPrimary],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 32)

                HStack(spacing: 8) {
                    TextField("Ask about your symptoms…", text: $input)
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .focused($isInputFocused)
                        .onSubmit { send(nil) }
                        .padding(.leading, 18)
                        .padding(.vertical, 10)

                    Button {
                        send(nil)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(input.trimmingCharacters(in: .whitespaces).isEmpty ? Color.bgInset : Color.sage)
                                .frame(width: 40, height: 40)
                            AppIcon(
                                name: "send",
                                size: 16,
                                color: input.trimmingCharacters(in: .whitespaces).isEmpty ? .fgFaint : .darkText
                            )
                        }
                        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: input.isEmpty)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.9))
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.trailing, 6)
                }
                .background(Color.bgCard)
                .overlay(Capsule().stroke(Color.strokeStrong, lineWidth: 0.5))
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .background(Color.bgPrimary)
    }

    private func send(_ text: String?) {
        let t = (text ?? input).trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        input = ""
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            appState.chatMessages.append(ChatMessage(role: .user, content: t))
            isTyping = true
        }

        let safety = RedFlagDetector.assess(text: t)
        if safety.hasRedFlags {
            appState.latestSafetyMessage = safety.safetyCopy
        }
        let response = safety.hasRedFlags
            ? safety.safetyCopy
            : responses[t] ?? "That's a thoughtful question. Inflamend can help you track context and prepare questions, but medication or care decisions should be reviewed with your GI clinician or pharmacist."
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isTyping = false
                appState.chatMessages.append(ChatMessage(role: .assistant, content: response))
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(message.content)
                .font(DS.sans(15))
                .foregroundColor(isUser ? .darkText : .fgPrimary)
                .lineSpacing(2)
                .tracking(-0.1)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    isUser ? Color.sage : Color.bgCard
                )
                .overlay(
                    !isUser ? RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.strokeDefault, lineWidth: 0.5) : nil
                )
                .clipShape(
                    BubbleShape(isUser: isUser)
                )
            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 20)
    }
}

struct BubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 22
        let tail: CGFloat = 8
        var p = Path()
        if isUser {
            p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height),
                             cornerSize: CGSize(width: r, height: r))
        } else {
            p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height),
                             cornerSize: CGSize(width: r, height: r))
        }
        return p
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.fgDim)
                    .frame(width: 6, height: 6)
                    .opacity(0.3 + 0.7 * sin(phase + Double(i) * 0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.strokeDefault, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

#Preview {
    ChatView(appState: AppState())
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
