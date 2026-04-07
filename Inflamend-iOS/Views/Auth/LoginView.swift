import SwiftUI

// MARK: - Welcome / Landing Screen

struct LoginView: View {
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            AppGradient.brand.ignoresSafeArea()

            GeometryReader { geo in
                Circle().fill(.white.opacity(0.07)).frame(width: 320)
                    .offset(x: geo.size.width * 0.55, y: -60)
                Circle().fill(.white.opacity(0.05)).frame(width: 240)
                    .offset(x: -60, y: geo.size.height * 0.6)
            }

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 96, height: 96)
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 44)).foregroundStyle(.white)
                }
                .scaleEffect(animateIn ? 1 : 0.6)
                .opacity(animateIn ? 1 : 0)
                .padding(.bottom, 28)

                VStack(spacing: 10) {
                    Text("Inflamend")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Track your IBD.\nLive with confidence.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .offset(y: animateIn ? 0 : 20)
                .opacity(animateIn ? 1 : 0)
                .padding(.bottom, 40)

                Spacer()

                HStack(spacing: 12) {
                    FeaturePill(icon: "chart.line.uptrend.xyaxis", label: "Track Trends")
                    FeaturePill(icon: "brain.head.profile",        label: "AI Support")
                    FeaturePill(icon: "pills.fill",                label: "Med Logs")
                }
                .offset(y: animateIn ? 0 : 30)
                .opacity(animateIn ? 1 : 0)

                Spacer().frame(height: 48)

                VStack(spacing: 14) {
                    Button { showSignUp = true } label: {
                        Text("Get Started")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.brandPrimary)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button { showSignIn = true } label: {
                        Text("I already have an account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.5), lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 28)
                .offset(y: animateIn ? 0 : 40)
                .opacity(animateIn ? 1 : 0)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
        .fullScreenCover(isPresented: $showSignUp) { SignupView() }
        .fullScreenCover(isPresented: $showSignIn) { SignInView() }
    }
}

// MARK: - Sign In Screen

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Welcome back")
                            .font(.title2).fontWeight(.bold)
                        Text("Sign in to your account")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Email")
                            TextField("you@example.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onChange(of: email) { _, v in
                                    if v.count > 254 { email = String(v.prefix(254)) }
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Password")
                            SecureField("••••••••", text: $password)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if let error {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.brandDanger)
                                Text(error).font(.footnote).foregroundStyle(.brandDanger)
                            }
                            .padding(12)
                            .background(Color.brandDanger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        PrimaryButton("Sign In", icon: "arrow.right", isLoading: loading) {
                            Task { await handleLogin() }
                        }

                        Button("Forgot password?") { showForgotPassword = true }
                            .font(.subheadline).foregroundStyle(.brandPrimary)
                    }
                }
                .padding(.horizontal, 24)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showForgotPassword) { ForgotPasswordView() }
        }
    }

    private func handleLogin() async {
        let trimmed = InputValidator.sanitize(email, maxLength: 254)
        guard !trimmed.isEmpty, !password.isEmpty else {
            error = "Please fill in all fields"; return
        }
        guard InputValidator.isValidEmail(trimmed) else {
            error = "Enter a valid email address"; return
        }
        loading = true; error = nil
        do {
            try await auth.signIn(email: trimmed, password: password)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var loading = false
    @State private var sent = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "envelope.badge.shield.half.filled.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(AppGradient.brand)
                        .padding(.top, 40)

                    VStack(spacing: 6) {
                        Text("Reset Password").font(.title2).fontWeight(.bold)
                        Text("Enter your email and we'll send a reset link.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if sent {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36)).foregroundStyle(.brandSuccess)
                            Text("Reset email sent. Check your inbox.")
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20).cardStyle()
                    } else {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                FieldLabel(text: "Email")
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding(14)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            if let error { Text(error).font(.footnote).foregroundStyle(.brandDanger) }
                            PrimaryButton("Send Reset Link", icon: "paperplane.fill", isLoading: loading) {
                                Task { await sendReset() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private func sendReset() async {
        let trimmed = InputValidator.sanitize(email, maxLength: 254)
        guard InputValidator.isValidEmail(trimmed) else { error = "Enter a valid email"; return }
        loading = true; error = nil
        do {
            try await AppDatabase.shared.resetPassword(email: trimmed)
            sent = true
        } catch { self.error = error.localizedDescription }
        loading = false
    }
}
