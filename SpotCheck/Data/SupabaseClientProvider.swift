import Foundation
import Supabase

/// The one Supabase client the app talks to.
///
/// Postgres columns are snake_case and Swift properties are camelCase, so the coders translate
/// between them once here rather than in every row type. The date handling matches what
/// PostgREST sends for `timestamptz`, which carries fractional seconds and sometimes does not.
enum SupabaseClientProvider {
    static let shared = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey,
        options: SupabaseClientOptions(
            db: SupabaseClientOptions.DatabaseOptions(encoder: encoder, decoder: decoder)
        )
    )

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(withFractionalSeconds.string(from: date))
        }
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = withFractionalSeconds.date(from: text) ?? withoutFractionalSeconds.date(from: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a date: \(text)")
            }
            return date
        }
        return decoder
    }()

    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let withoutFractionalSeconds = ISO8601DateFormatter()
}
