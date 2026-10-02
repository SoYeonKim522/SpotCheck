import Foundation

/// The one file the app and the widget share.
///
/// The two halves are written at different moments. Reading a building updates the counts;
/// checking in, extending or releasing updates the hold. Each write keeps the other half, so
/// a check-in does not wipe the counts and a refresh does not wipe the seat she is holding.
///
/// Nobody can act on a failure here, so a failed write is not an error anyone is shown. The
/// widget keeps the previous snapshot, which is the behaviour it is built for anyway.
enum AvailabilitySnapshotStore {
    static func read() -> AvailabilitySnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(AvailabilitySnapshot.self, from: data)
    }

    static func write(levels: [AvailabilitySnapshot.LevelCount], inBuilding buildingName: String, readAt: Date) {
        write(
            AvailabilitySnapshot(
                buildingName: buildingName,
                levels: levels,
                hold: read()?.hold,
                readAt: readAt
            )
        )
    }

    static func write(hold: AvailabilitySnapshot.HeldSeat?) {
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

    private static func write(_ snapshot: AvailabilitySnapshot) {
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

    private static var fileURL: URL? {
        AppGroup.containerURL?.appending(path: "availability.json")
    }
}
