//
//  SeedData.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 10/9/2026.
//

import Foundation
import SwiftData

enum SeedData {
    static func loadIfEmpty(into context: ModelContext, now: Date) throws {
        guard try context.fetchCount(FetchDescriptor<CampusBuilding>()) == 0 else { return }

        let building2Level5ReadingRoom = zone("Reading Room", .silent, seats("5R", 16, hasPowerOutlet: true, hasPartition: true))
        let building2Level5OpenStudy = zone("Open Study", .collaborative, seats("5A", 10, hasPowerOutlet: true, isSharedTable: true))
        let building2Level6Library = zone("Library", .quiet, seats("6L", 10, hasPowerOutlet: true, hasPartition: true))
        let building2Level7Library = zone("Library", .quiet, seats("7L", 14, hasPowerOutlet: true) + seats("7W", 6, isByWindow: true))
        let building2Level8Library = zone("Library", .quiet, seats("8L", 18, hasPowerOutlet: true, hasPartition: true))
        let building2Level9Library = zone("Library", .quiet, seats("9L", 12, hasPartition: true) + seats("9C", 6, hasComputer: true, hasPowerOutlet: true))

        let building2Level4 = level(4, [
            zone("Open Study", .collaborative,
                 seats("4A", 12, hasPowerOutlet: true, isSharedTable: true)
                 + seats("4B", 8, isByWindow: true, isSharedTable: true))
        ])
        let building2Level5 = level(5, [building2Level5ReadingRoom, building2Level5OpenStudy])
        let building2Level6 = level(6, [
            zone("Open Study", .collaborative, seats("6A", 12, isSharedTable: true)),
            building2Level6Library
        ])
        let building2Level7 = level(7, [building2Level7Library])
        let building2Level8 = level(8, [building2Level8Library])
        let building2Level9 = level(9, [building2Level9Library])

        let building2 = building("Building 2", "61 Broadway, Ultimo", [
            building2Level4, building2Level5, building2Level6, building2Level7, building2Level8, building2Level9
        ])

        let building1Level3 = level(3, [zone("Open Study", .collaborative, seats("T3", 8, isSharedTable: true))])
        let building1Level4 = level(4, [zone("Open Study", .collaborative, seats("T4", 10, hasPowerOutlet: true, isSharedTable: true))])
        let building1 = building("Building 1", "15 Broadway, Ultimo", [building1Level3, building1Level4])

        let building11Level5 = level(5, [zone("Open Study", .collaborative, seats("E5", 12, hasPowerOutlet: true, isSharedTable: true))])
        let building11Level6 = level(6, [zone("Open Study", .collaborative, seats("E6", 10, isByWindow: true, isSharedTable: true))])
        let building11 = building("Building 11", "81 Broadway, Ultimo", [building11Level5, building11Level6])

        for campusBuilding in [building2, building1, building11] {
            context.insert(campusBuilding)
        }

        let seatsHeld: [(StudyLevel, Int)] = [
            (building2Level4, 5),
            (building2Level5, 17),
            (building2Level6, 21),
            (building2Level7, 7),
            (building2Level8, 10),
            (building2Level9, 3),
            (building1Level3, 2),
            (building1Level4, 6),
            (building11Level5, 10),
            (building11Level6, 3)
        ]

        var occupantNumber = 0
        for (studyLevel, occupiedSeats) in seatsHeld {
            for seat in spread(occupiedSeats, over: studyLevel.zones.flatMap(\.seats)) {
                occupantNumber += 1
                let checkedInAt = now.addingTimeInterval(-Double(1 + occupantNumber % 25) * 60)
                context.insert(
                    SeatCheckIn(
                        checkedInBy: OccupantIdentifier(value: "seed-occupant-\(occupantNumber)"),
                        seat: seat,
                        checkedInAt: checkedInAt,
                        expiresAt: checkedInAt.addingTimeInterval(SeatHoldPolicy.duration)
                    )
                )
            }
        }

        if let longVacatedSeat = building2Level9Library.seats.last {
            let expiredAt = now.addingTimeInterval(-74 * 60)
            context.insert(
                SeatCheckIn(
                    checkedInBy: OccupantIdentifier(value: "seed-occupant-expired"),
                    seat: longVacatedSeat,
                    checkedInAt: expiredAt,
                    expiresAt: expiredAt.addingTimeInterval(SeatHoldPolicy.duration)
                )
            )
        }

        try context.save()
    }

    private static func spread(_ count: Int, over seats: [StudySeat]) -> [StudySeat] {
        guard count > 0, count <= seats.count else { return seats }
        return (0..<count).map { seats[$0 * seats.count / count] }
    }

    private static func building(_ name: String, _ address: String, _ levels: [StudyLevel]) -> CampusBuilding {
        let campusBuilding = CampusBuilding(name: name, address: address)
        campusBuilding.levels = levels
        return campusBuilding
    }

    private static func level(_ number: Int, _ zones: [StudyZone]) -> StudyLevel {
        let studyLevel = StudyLevel(number: number)
        studyLevel.zones = zones
        return studyLevel
    }

    private static func zone(_ name: String, _ noiseLevel: NoiseLevel?, _ seats: [StudySeat]) -> StudyZone {
        let studyZone = StudyZone(name: name, noiseLevel: noiseLevel)
        studyZone.seats = seats
        return studyZone
    }

    private static func seats(
        _ prefix: String,
        _ count: Int,
        isByWindow: Bool = false,
        hasComputer: Bool = false,
        hasPowerOutlet: Bool = false,
        hasPartition: Bool = false,
        isSharedTable: Bool = false
    ) -> [StudySeat] {
        (1...count).map { index in
            StudySeat(
                label: "\(prefix)\(index)",
                isByWindow: isByWindow,
                hasComputer: hasComputer,
                hasPowerOutlet: hasPowerOutlet,
                hasPartition: hasPartition,
                isSharedTable: isSharedTable
            )
        }
    }
}
