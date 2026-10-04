import Foundation

/// Writes the snapshot the widget reads. The use cases depend on this protocol, so a test can
/// check what was written without touching the App Group container.
protocol AvailabilitySnapshotWriting {
    func write(levels: [AvailabilitySnapshot.LevelCount], inBuilding buildingName: String, readAt: Date)
    func write(hold: AvailabilitySnapshot.HeldSeat?)
}

/// The snapshot file the app and the widget share.
///
/// It holds the seat counts and the held seat. A write to one keeps the other, so checking in
/// does not wipe the counts and a refresh does not wipe the held seat.
///
/// A failed write keeps the old file, so the widget still shows the last snapshot that worked.
struct AvailabilitySnapshotStore: AvailabilitySnapshotWriting {
    func read() -> AvailabilitySnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(AvailabilitySnapshot.self, from: data)
    }

    func write(levels: [AvailabilitySnapshot.LevelCount], inBuilding buildingName: String, readAt: Date) {
        write(
            AvailabilitySnapshot(
                buildingName: buildingName,
                levels: levels,
                hold: read()?.hold,
                readAt: readAt
            )
        )
    }

    func write(hold: AvailabilitySnapshot.HeldSeat?) {
        let previous = read()
        write(
            AvailabilitySnapshot(
                buildingName: previous?.buildingName ?? "",
                levels: previous?.levels ?? [],
                hold: hold,
                readAt: previous?.readAt ?? .distantPast
            )
        )
    }

    private func write(_ snapshot: AvailabilitySnapshot) {
        guard let fileURL else {
            assertionFailure("The App Group container is missing. Check the entitlement on every target.")
            return
        }
        do {
            try JSONEncoder().encode(snapshot).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("The availability snapshot could not be written: \(error)")
        }
    }

    private var fileURL: URL? {
        AppGroup.containerURL?.appending(path: "availability.json")
    }
}
