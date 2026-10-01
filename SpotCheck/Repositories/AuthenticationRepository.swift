import Foundation

protocol AuthenticationRepository {
    func restoreOccupant() async -> OccupantIdentifier?
    func signIn(email: String, password: String) async throws -> OccupantIdentifier
    func signOut() async throws
}

enum AuthenticationError: LocalizedError {
    case emailOrPasswordIsWrong
    case emailIsNotConfirmed
    case couldNotReachTheServer

    var errorDescription: String? {
        switch self {
        case .emailOrPasswordIsWrong:
            "That email and password don't match an account."
        case .emailIsNotConfirmed:
            "This email address hasn't been confirmed yet."
        case .couldNotReachTheServer:
            "We couldn't reach SpotCheck just now."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emailOrPasswordIsWrong:
            "Check them and try again."
        case .emailIsNotConfirmed:
            "Open the link in the email we sent you, then sign in."
        case .couldNotReachTheServer:
            "Check your connection and try again."
        }
    }
}
