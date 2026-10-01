import Foundation

/// One floor of a building, which students can choose from.
///
/// Floors can differ in noise, zone type, and seat features, so availability is shown
/// separately for each floor rather than for the whole building.
struct StudyLevel: Identifiable, Hashable {
    let id: UUID
    let buildingID: UUID
    let number: Int
}
