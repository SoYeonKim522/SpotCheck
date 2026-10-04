import Foundation
import Testing
@testable import SpotCheck

@MainActor
struct StudySpaceRowsTests {
    private let nineAM = Date(timeIntervalSince1970: 1_791_190_800)
    private let tenAM = Date(timeIntervalSince1970: 1_791_194_400)

    @Test func seatsInAZoneAreSortedNaturallyByLabel() throws {
        let zone: ZoneRow = try decode("""
            {"id":"\(UUID())","level_id":"\(UUID())","name":"Library","noise_level":"quiet",
             "seats":[\(seatJSON(label: "6L10")),\(seatJSON(label: "6L2")),\(seatJSON(label: "6L1"))]}
            """)

        #expect(zone.zone.seats.map(\.label) == ["6L1", "6L2", "6L10"])
    }

    @Test func aHoldReadsItsSeatZoneLevelAndBuildingFromTheNestedRows() throws {
        let row: HoldRow = try decode("""
            {"id":"\(UUID())","seat_id":"\(UUID())","occupant_id":"\(UUID())",
             "checked_in_at":"2026-10-05T09:00:00+00:00","expires_at":"2026-10-05T10:00:00+00:00",
             "released_at":null,
             "seats":{"label":"5R4","zones":{"name":"Reading Room",
                      "levels":{"number":5,"buildings":{"name":"Building 2"}}}}}
            """)

        let hold = row.hold

        #expect(hold.seatLabel == "5R4")
        #expect(hold.zoneName == "Reading Room")
        #expect(hold.levelNumber == 5)
        #expect(hold.buildingName == "Building 2")
        #expect(hold.checkIn.releasedAt == nil)
    }

    @Test func timestampsDecodeWithAndWithoutFractionalSeconds() throws {
        let row: CheckInRow = try decode("""
            {"id":"\(UUID())","seat_id":"\(UUID())","occupant_id":"\(UUID())",
             "checked_in_at":"2026-10-05T09:00:00.123456+00:00","expires_at":"2026-10-05T10:00:00+00:00",
             "released_at":null}
            """)

        #expect(abs(row.checkedInAt.timeIntervalSince(nineAM) - 0.123456) < 0.001)
        #expect(row.expiresAt == tenAM)
    }

    @Test func updatingACheckInOnlySendsItsExpiryAndRelease() throws {
        let checkIn = TestData.checkIn(releasedAt: TestData.now.addingTimeInterval(10 * 60))

        let data = try SupabaseClientProvider.encoder.encode(CheckInChangeRow(checkIn))
        let sent = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(sent.keys) == ["expires_at", "released_at"])
    }

    private func decode<Row: Decodable>(_ json: String) throws -> Row {
        try SupabaseClientProvider.decoder.decode(Row.self, from: Data(json.utf8))
    }

    private func seatJSON(label: String) -> String {
        """
        {"id":"\(UUID())","zone_id":"\(UUID())","label":"\(label)","is_by_window":false,
         "has_computer":false,"has_power_outlet":false,"has_partition":false,"is_shared_table":false,
         "seat_check_ins":[]}
        """
    }
}
