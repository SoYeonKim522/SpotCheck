import Foundation

/// The noise level assigned to a zone by the university.
enum NoiseLevel: String, Codable {
    case silent
    case quiet
    case collaborative

    var displayName: String {
        switch self {
        case .silent: "Silent"
        case .quiet: "Quiet"
        case .collaborative: "Collaborative"
        }
    }
}
