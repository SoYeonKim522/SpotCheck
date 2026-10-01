import Foundation
import Supabase

struct SupabaseAuthenticationRepository: AuthenticationRepository {
    let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func restoreOccupant() async -> OccupantIdentifier? {
        guard let session = try? await client.auth.session else { return nil }
        return OccupantIdentifier(value: session.user.id)
    }

    func signIn(email: String, password: String) async throws -> OccupantIdentifier {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return OccupantIdentifier(value: session.user.id)
        } catch {
            throw mapped(error)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw mapped(error)
        }
    }

    private func mapped(_ error: any Error) -> AuthenticationError {
        guard let authError = error as? AuthError else { return .couldNotReachTheServer }
        switch authError.errorCode {
        case .invalidCredentials: return .emailOrPasswordIsWrong
        case .emailNotConfirmed: return .emailIsNotConfirmed
        default: return .couldNotReachTheServer
        }
    }
}
