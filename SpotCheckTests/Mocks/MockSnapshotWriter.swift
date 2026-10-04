import Foundation
@testable import SpotCheck

final class MockSnapshotWriter: AvailabilitySnapshotWriting {
    private(set) var writtenLevels: [(levels: [AvailabilitySnapshot.LevelCount], buildingName: String, readAt: Date)] = []
    private(set) var writtenHolds: [AvailabilitySnapshot.HeldSeat?] = []

    func write(levels: [AvailabilitySnapshot.LevelCount], inBuilding buildingName: String, readAt: Date) {
        writtenLevels.append((levels, buildingName, readAt))
    }

    func write(hold: AvailabilitySnapshot.HeldSeat?) {
        writtenHolds.append(hold)
    }
}
