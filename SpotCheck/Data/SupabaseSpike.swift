import Foundation
import Supabase

enum SupabaseSpike {
    struct Counts {
        let signedInAs: String
        let seats: Int
        let activeCheckIns: Int
    }

    struct SeatRow: Decodable {
        let id: UUID
    }

    static func readCounts() async throws -> Counts {
        let client = SupabaseClientProvider.shared

        let session = try await client.auth.session
        let signedInAs = "\(session.user.email ?? "no email") role \(session.user.role ?? "no role")"

        let seats: [SeatRow] = try await client
            .from("seats")
            .select("id")
            .execute()
            .value

        let activeCheckIns: [SeatRow] = try await client
            .from("seat_check_ins")
            .select("id")
            .is("released_at", value: nil)
            .gt("expires_at", value: Date.now)
            .execute()
            .value

        return Counts(
            signedInAs: signedInAs,
            seats: seats.count,
            activeCheckIns: activeCheckIns.count
        )
    }
}
