//
//  LevelListViewModel.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 12/9/2026.
//

import Foundation
import Observation

@Observable
final class LevelListViewModel {
    private let repository: StudySpaceRepository
    private let viewLevelAvailability = ViewLevelAvailabilityUseCase()

    private(set) var buildings: [CampusBuilding] = []
    private(set) var availabilities: [LevelAvailability] = []
    private(set) var selectedBuilding: CampusBuilding?

    init(repository: StudySpaceRepository) {
        self.repository = repository
    }

    var lastUpdatedAt: Date? {
        availabilities.compactMap(\.lastUpdatedAt).max()
    }

    func select(building: CampusBuilding, now: Date) {
        selectedBuilding = building
        refresh(now: now)
    }

    func refresh(now: Date) {
        buildings = (try? repository.buildings()) ?? []
        selectedBuilding = selectedBuilding ?? buildings.first
        availabilities = selectedBuilding.map { viewLevelAvailability.execute(building: $0, now: now) } ?? []
    }
}
