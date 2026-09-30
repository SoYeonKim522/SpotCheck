import Supabase

nonisolated struct SpikeRow: Decodable, Sendable {
    let id: Int
    let name: String
}

enum SupabaseSpike {
    static func run() async {
        let client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
        do {
            let rows: [SpikeRow] = try await client.from("spike").select().execute().value
            print("Supabase spike rows: \(rows)")
        } catch {
            print("Supabase spike failed: \(error)")
        }
    }
}
