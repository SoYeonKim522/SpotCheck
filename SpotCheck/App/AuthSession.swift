import Foundation
import Observation

@MainActor
@Observable
final class AuthSession {
    private(set) var occupant: OccupantIdentifier?
    private(set) var isWorking = false
    private(set) var errorText: String?

    private let repository: any AuthenticationRepository

    init(repository: any AuthenticationRepository) {
        self.repository = repository
    }

    var isSignedIn: Bool {
        occupant != nil
    }

    func restore() async {
        occupant = await repository.restoreOccupant()
    }

    func signIn(email: String, password: String) async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }

        do {
            occupant = try await repository.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch {
            errorText = message(for: error)
        }
    }

    func signOut() async {
        isWorking = true
        errorText = nil
        defer { isWorking = false }

        do {
            try await repository.signOut()
            occupant = nil
        } catch {
            errorText = message(for: error)
        }
    }

    private func message(for error: any Error) -> String {
        let authenticationError = error as? AuthenticationError ?? .couldNotReachTheServer
        return [authenticationError.errorDescription, authenticationError.recoverySuggestion]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}
