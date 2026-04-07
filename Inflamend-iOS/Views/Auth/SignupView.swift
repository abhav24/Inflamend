import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var diagnosisType: DiagnosisType? = nil
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppGradient.brand)
                            .frame(width: 64, height: 64)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 32)

                    Text("Create Account")
                        .font(.title2).fontWeight(.bold)
                    Text("Start tracking your IBD journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 16) {
                    formField("Display Name", systemIcon: "person", text: $displayName)
                    formField("Email", systemIcon: "envelope", text: $email, keyboard: .emailAddress)
                    secureField("Password", systemIcon: "lock", text: $password)
                    secureField("Confirm Password", systemIcon: "lock.fill", text: $confirmPassword)

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: "Diagnosis")
                        Picker("Diagnosis", selection: $diagnosisType) {
                            Text("Select diagnosis (optional)").tag(DiagnosisType?.none)
                            ForEach(DiagnosisType.allCases, id: \.self) { d in
                                Text(d.label).tag(DiagnosisType?.some(d))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                    PrimaryButton("Create Account", icon: "checkmark", isLoading: loading) {
                        Task { await handleSignup() }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func formField(_ placeholder: String, systemIcon: String, text: Binding<String>,
                            keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: placeholder)
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(keyboard == .emailAddress ? .none : .words)
                    .autocorrectionDisabled()
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func secureField(_ placeholder: String, systemIcon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: placeholder)
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                SecureField(placeholder, text: text)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func handleSignup() async {
        let emailTrimmed = email.trimmingCharacters(in: .whitespaces)
        guard !emailTrimmed.isEmpty, !password.isEmpty, !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please fill in all required fields"
            return
        }
        guard password == confirmPassword else {
            error = "Passwords do not match"
            return
        }
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            return
        }
        loading = true
        error = nil
        do {
            try await SupabaseClient.shared.signUp(email: emailTrimmed, password: password)
            try await auth.signIn(email: emailTrimmed, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
