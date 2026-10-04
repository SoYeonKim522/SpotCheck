import Foundation

/// A named area within a level, such as a reading room or open seating.
///
/// `noiseLevel` uses the university's official designation. If the university
/// has not provided one, it is `nil`. It is not based on personal opinions.
struct StudyZone: Identifiable, Hashable {
    let id: UUID
    let levelID: UUID
    let name: String
    let noiseLevel: NoiseLevel?
    let seats: [StudySeat]

    var capacity: Int {
        seats.count
    }
}
