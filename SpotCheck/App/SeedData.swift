//
//  SeedData.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 10/9/2026.
//

import Foundation
import SwiftData

enum SeedData {
    private static let holdDuration: TimeInterval = 60 * 60

    static func loadIfEmpty(into context: ModelContext, now: Date) throws {
        guard try context.fetchCount(FetchDescriptor<CampusBuilding>()) == 0 else { return }

        let readingRoom = zone("Reading Room", .silent, seats("5R", 16, hasPowerOutlet: true, hasPartition: true))
        let level5Open = zone("Open Study", .collaborative, seats("5A", 10, hasPowerOutlet: true, isSharedTable: true))
        let level6Library = zone("Library", .quiet, seats("6L", 10, hasPowerOutlet: true, hasPartition: true))
        let level7Library = zone("Library", .quiet, seats("7L", 14, hasPowerOutlet: true) + seats("7W", 6, isByWindow: true))
        let level8Library = zone("Library", .quiet, seats("8L", 18, hasPowerOutlet: true, hasPartition: true))
        let level9Library = zone("Library", .quiet, seats("9L", 12, hasPartition: true) + seats("9C", 6, hasComputer: true, hasPowerOutlet: true))

        let utsCentral = building("Building 2", "61 Broadway, Ultimo", [
            level(4, [
                zone("Open Study", .collaborative,
                     seats("4A", 12, hasPowerOutlet: true, isSharedTable: true)
                     + seats("4B", 8, isByWindow: true, isSharedTable: true))
            ]),
            level(5, [readingRoom, level5Open]),
            level(6, [
                zone("Open Study", .collaborative, seats("6A", 12, isSharedTable: true)),
                level6Library
            ]),
            level(7, [level7Library]),
            level(8, [level8Library]),
            level(9, [level9Library])
        ])

        let utsTower = building("Building 1", "15 Broadway, Ultimo", [
            level(3, [zone("Open Study", .collaborative, seats("T3", 8, isSharedTable: true))]),
            level(4, [zone("Open Study", .collaborative, seats("T4", 10, hasPowerOutlet: true, isSharedTable: true))])
        ])

        let engineering = building("Building 11", "81 Broadway, Ultimo", [
            level(5, [zone("Open Study", .collaborative, seats("E5", 12, hasPowerOutlet: true, isSharedTable: true))]),
            level(6, [zone("Open Study", .collaborative, seats("E6", 10, isByWindow: true, isSharedTable: true))])
        ])

        for campusBuilding in [utsCentral, utsTower, engineering] {
            context.insert(campusBuilding)
        }

        let occupants = (1...6).map { OccupantIdentifier(value: "seed-occupant-\($0)") }
        let held: [(StudySeat, OccupantIdentifier, TimeInterval)] = [
            (readingRoom.seats[0], occupants[0], -4 * 60),
            (readingRoom.seats[5], occupants[1], -18 * 60),
            (level5Open.seats[2], occupants[2], -33 * 60),
            (level7Library.seats[1], occupants[3], -51 * 60),
            (level8Library.seats[9], occupants[4], -12 * 60),
            (level9Library.seats[4], occupants[5], -74 * 60)  //expired
        ]

        for (seat, occupant, offset) in held {
            let checkedInAt = now.addingTimeInterval(offset)
            context.insert(
                SeatCheckIn(
                    checkedInBy: occupant,
                    seat: seat,
                    checkedInAt: checkedInAt,
                    expiresAt: checkedInAt.addingTimeInterval(holdDuration)
                )
            )
        }

        try context.save()
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
