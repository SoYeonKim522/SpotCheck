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

    private var canSignIn: Bool {
        !session.isWorking && !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { signIn() }
                } footer: {
                    Text("Signing in keeps the seat you check into yours, and it keeps the free seat counts other students rely on honest.")
                }

                if let errorText = session.errorText {
                    Section {
                        Text(errorText)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(action: signIn) {
                        if session.isWorking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign in")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!canSignIn)
                }
            }
            .navigationTitle("Sign in")
        }
    }

    private func signIn() {
        guard canSignIn else { return }
        focusedField = nil
        Task { await session.signIn(email: email, password: password) }
    }
}
