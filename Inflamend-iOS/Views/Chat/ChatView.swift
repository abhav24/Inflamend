import SwiftUI

struct ChatView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var sending = false
    @State private var loading = false
    @State private var initialLoad = true
    @FocusState private var inputFocused: Bool

    private let db = AppDatabase.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                if initialLoad {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if messages.isEmpty && !loading {
                    starterView
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { msg in
                                    MessageBubble(message: msg)
                                        .id(msg.id)
                                }
                                if loading {
                                    TypingIndicator()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo(messages.last?.id ?? "typing", anchor: .bottom)
                            }
                        }
                        .onChange(of: loading) { _, _ in
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input bar
                inputBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Health Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await fetchMessages() }
    }

    // MARK: - Starter View

    private var starterView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(AppGradient.brand).frame(width: 44, height: 44)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IBD Support Assistant")
                            .font(.subheadline).fontWeight(.bold)
                        Text("Your personal health companion")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 4)

                Text("Hi! I'm here to help you with questions about IBD, your symptoms, diet, and more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Suggested questions")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    ForEach(starterQuestions, id: \.self) { question in
                        Button {
                            Task { await sendMessage(question) }
                        } label: {
                            HStack {
                                Text(question)
                                    .font(.subheadline)
                                    .foregroundStyle(.brandPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(.brandPrimary.opacity(0.5))
                            }
                            .padding(14)
                            .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask me anything about IBD...", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .focused($inputFocused)

            Button {
                Task { await sendMessage(inputText) }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        inputText.trimmingCharacters(in: .whitespaces).isEmpty || sending
                            ? AnyShapeStyle(Color(.systemFill))
                            : AnyShapeStyle(AppGradient.brand)
                    )
                    .clipShape(Circle())
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || sending || loading)
            .animation(.easeInOut(duration: 0.2), value: inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Logic

    private func fetchMessages() async {
        guard let uid = db.userId else { initialLoad = false; return }
        let fetched: [ChatMessage] = (try? await db.select("chat_messages",
            filter: "user_id=eq.\(uid)")) ?? []
        let sorted = fetched.sorted { $0.created_at < $1.created_at }
        messages = sorted
        initialLoad = false
    }

    private func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !sending, !loading, let uid = db.userId else { return }

        sending = true
        inputText = ""

        let userMsg = ChatMessage(
            id: UUID().uuidString, user_id: uid, role: .user,
            content: trimmed, created_at: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(userMsg)

        struct MsgPayload: Encodable {
            let id: String; let user_id: String; let role: String; let content: String; let created_at: String
        }
        _ = try? await db.insert("chat_messages", data: MsgPayload(id: userMsg.id, user_id: uid,
            role: userMsg.role.rawValue, content: userMsg.content, created_at: userMsg.created_at))

        sending = false
        loading = true

        do {
            struct ChatBody: Encodable {
                let messages: [[String: String]]
                let userId: String
            }
            let last20 = messages.suffix(20).map { ["role": $0.role.rawValue, "content": $0.content] }
            let data = try await db.invokeFunction("chat", body: ChatBody(messages: last20, userId: uid))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let responseText = json?["content"] as? String ?? "Sorry, I could not generate a response."

            let assistantMsg = ChatMessage(
                id: UUID().uuidString, user_id: uid, role: .assistant,
                content: responseText, created_at: ISO8601DateFormatter().string(from: Date())
            )
            messages.append(assistantMsg)
            _ = try? await db.insert("chat_messages", data: MsgPayload(id: assistantMsg.id, user_id: uid,
                role: assistantMsg.role.rawValue, content: assistantMsg.content, created_at: assistantMsg.created_at))
        } catch {
            let errMsg = ChatMessage(
                id: UUID().uuidString, user_id: uid, role: .assistant,
                content: "Sorry, something went wrong. Please try again in a moment.",
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            messages.append(errMsg)
        }
        loading = false
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle().fill(AppGradient.brand).frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? AnyShapeStyle(AppGradient.brand)
                            : AnyShapeStyle(Color(.secondarySystemBackground))
                    )
                    .clipShape(
                        .rect(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: isUser ? 16 : 4,
                            bottomTrailingRadius: isUser ? 4 : 16,
                            topTrailingRadius: 16
                        )
                    )

                Text(formatTime(message.created_at))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    private func formatTime(_ iso: String) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = fmt.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(AppGradient.brand).frame(width: 32, height: 32)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondary.opacity(phase == i ? 1 : 0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.15).repeatForever(), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation { phase = 1 }
        }
    }
}
