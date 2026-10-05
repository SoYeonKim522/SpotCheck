import SwiftUI

struct SignInView: View {
    private enum Field {
        case email
        case password
    }

    @Environment(AuthSession.self) private var session

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private var hasDetails: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private var canSignIn: Bool {
        !session.isWorking && hasDetails
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Circle()
                .fill(Color.holdGreen)
                .overlay { Circle().stroke(.primary, lineWidth: 2) }
                .frame(width: 64, height: 64)
                .padding(.top, 24)

            Text("Sign in")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                field("Email") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                Divider()
                field("Password") {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { signIn() }
                }
            }
            .padding(.horizontal, 20)
            .card()

            Text("Signing in keeps the seat you check into yours, and it keeps the free seat counts other students rely on honest.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            if let errorText = session.errorText {
                Text(errorText)
                    .foregroundStyle(Color.releaseRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemBackground), in: .rect(cornerRadius: 20))
                    .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.releaseRed, lineWidth: 2) }
            }

            Spacer()

            Button(action: signIn) {
                signInLabel
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(hasDetails ? Color.holdGreen : Color(.systemGray6), in: .capsule)
                    .overlay { Capsule().stroke(hasDetails ? Color.primary : Color(.systemGray4), lineWidth: 2) }
                    .contentShape(.capsule)
            }
            .buttonStyle(PressedButtonStyle())
            .disabled(!canSignIn)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var signInLabel: some View {
        if session.isWorking {
            HStack(spacing: 8) {
                ProgressView()
                Text("Signing in…")
            }
            .foregroundStyle(Color.holdGreenText)
        } else {
            Text("Sign in")
                .foregroundStyle(hasDetails ? Color.holdGreenText : .secondary)
        }
    }

    private func field(_ title: String, @ViewBuilder input: () -> some View) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)
            input()
        }
        .padding(.vertical, 20)
    }

    private func signIn() {
        guard canSignIn else { return }
        focusedField = nil
        Task { await session.signIn(email: email, password: password) }
    }
}

private struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
    }
}
