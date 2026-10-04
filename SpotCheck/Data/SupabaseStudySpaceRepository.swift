import Foundation
import Supabase

/// Reads study spaces and writes check-ins through Supabase.
///
/// Every read asks Postgres for only the check-ins that are active at `moment`.
/// Counting the free seats is left to the use cases.
struct SupabaseStudySpaceRepository: StudySpaceRepository {
    let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func buildings() async throws -> [CampusBuilding] {
        let rows: [BuildingRow] = try await client
            .from("buildings")
            .select("id,name,address,display_order")
            .order("display_order")
            .execute()
            .value
        return rows.map(\.building)
    }

    func levels(inBuilding buildingID: UUID, at moment: Date) async throws -> [StudyLevel] {
        let rows: [LevelRow] = try await client
            .from("levels")
            .select("id,building_id,number,zones(id,level_id,name,noise_level,seats(id,zone_id,label,is_by_window,has_computer,has_power_outlet,has_partition,is_shared_table,seat_check_ins(id,seat_id,occupant_id,checked_in_at,expires_at,released_at)))")
            .eq("building_id", value: buildingID)
            .is("zones.seats.seat_check_ins.released_at", value: nil)
            .gt("zones.seats.seat_check_ins.expires_at", value: moment)
            .order("number")
            .execute()
            .value

        return rows.map(\.level)
    }

    func zones(onLevel levelID: UUID, at moment: Date) async throws -> [StudyZone] {
        let rows: [ZoneRow] = try await client
            .from("zones")
            .select("id,level_id,name,noise_level,seats(id,zone_id,label,is_by_window,has_computer,has_power_outlet,has_partition,is_shared_table,seat_check_ins(id,seat_id,occupant_id,checked_in_at,expires_at,released_at))")
            .eq("level_id", value: levelID)
            .is("seats.seat_check_ins.released_at", value: nil)
            .gt("seats.seat_check_ins.expires_at", value: moment)
            .execute()
            .value

        return rows
            .map(\.zone)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func activeHold(for occupant: OccupantIdentifier, at moment: Date) async throws -> SeatHold? {
        let rows: [HoldRow] = try await client
            .from("seat_check_ins")
            .select("id,seat_id,occupant_id,checked_in_at,expires_at,released_at,seats!inner(label,zones!inner(name,levels!inner(number,buildings!inner(name))))")
            .eq("occupant_id", value: occupant.value)
            .is("released_at", value: nil)
            .gt("expires_at", value: moment)
            .limit(1)
            .execute()
            .value
        return rows.first?.hold
    }

    func activeCheckIn(onSeat seatID: UUID, at moment: Date) async throws -> SeatCheckIn? {
        let rows: [CheckInRow] = try await client
            .from("seat_check_ins")
            .select("id,seat_id,occupant_id,checked_in_at,expires_at,released_at")
            .eq("seat_id", value: seatID)
            .is("released_at", value: nil)
            .gt("expires_at", value: moment)
            .limit(1)
            .execute()
            .value
        return rows.first?.checkIn
    }

    func add(_ checkIn: SeatCheckIn) async throws {
        try await client
            .from("seat_check_ins")
            .insert(NewCheckInRow(checkIn))
            .execute()
    }

    func update(_ checkIn: SeatCheckIn) async throws {
        try await client
            .from("seat_check_ins")
            .update(CheckInChangeRow(checkIn))
            .eq("id", value: checkIn.id)
            .execute()
    }
}
