import Foundation

/// A building on the UTS campus that students can study in.
///
/// Names are unique because a name is also what students see and choose by ("Building 2").
/// `displayOrder` exists because the names are the numbers students use, and sorting those
/// as text gives Building 1, Building 11, Building 2.
struct CampusBuilding: Identifiable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let displayOrder: Int
}
