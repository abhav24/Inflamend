import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?
    @State private var showSignup = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppGradient.brand)
                                .frame(width: 80, height: 80)
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text("Inflamend")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AppGradient.brand)
                        Text("Your Gut's Best Friend")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Form
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
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.brandDanger)
                            }
                            .padding(12)
                            .background(Color.brandDanger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        PrimaryButton("Sign In", icon: "arrow.right", isLoading: loading) {
                            Task { await handleLogin() }
                        }

                        Button("Forgot password?") { showForgotPassword = true }
                            .font(.subheadline)
                            .foregroundStyle(.brandPrimary)

                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Button("Sign up") { showSignup = true }
                                .foregroundStyle(.brandPrimary)
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $showSignup) { SignupView() }
            .sheet(isPresented: $showForgotPassword) { ForgotPasswordView() }
        }
    }

    private func handleLogin() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            error = "Please fill in all fields"
            return
        }
        loading = true
        error = nil
        do {
            try await auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

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
                        Text("Reset Password")
                            .font(.title2).fontWeight(.bold)
                        Text("Enter your email and we'll send a reset link.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if sent {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.brandSuccess)
                            Text("Reset email sent. Check your inbox.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .cardStyle()
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

                            if let error {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.brandDanger)
                            }

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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func sendReset() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your email"
            return
        }
        loading = true
        error = nil
        do {
            try await SupabaseClient.shared.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            sent = true
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
