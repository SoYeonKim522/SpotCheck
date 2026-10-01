import SwiftUI

struct RootView: View {
    @State private var session = AuthSession(repository: SupabaseAuthenticationRepository())
    @State private var hasRestored = false

    var body: some View {
        Group {
            if !hasRestored {
                ProgressView()
            } else if session.isSignedIn {
                FindASeatPlaceholder()
            } else {
                SignInView()
            }
        }
        .environment(session)
        .task {
            await session.restore()
            hasRestored = true
        }
    }
}

private struct FindASeatPlaceholder: View {
    @Environment(AuthSession.self) private var session

    @State private var counts: SupabaseSpike.Counts?
    @State private var failure: String?

    var body: some View {
        VStack(spacing: 12) {
            if let counts {
                Text(counts.signedInAs)
                Text("\(counts.seats) seats")
                Text("\(counts.activeCheckIns) held right now")
            } else if let failure {
                Text(failure)
                    .textSelection(.enabled)
            } else {
                ProgressView()
            }

            Button("Sign out") {
                Task { await session.signOut() }
            }
        }
        .task {
            do {
                counts = try await SupabaseSpike.readCounts()
            } catch {
                failure = error.localizedDescription
            }
        }
    }
}
