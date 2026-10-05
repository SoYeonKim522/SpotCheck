import Foundation
import Observation

/// Holds what the level list shows: the buildings, the chosen building and its levels.
///
/// The list opens on the building the student chose last time. A read that does not arrive
/// puts the screen in `couldNotReach`, which the view shows with a retry.
@MainActor
@Observable
final class LevelListViewModel {
    enum State {
        case loading
        case loaded
        case couldNotReach
    }

    private(set) var state = State.loading
    private(set) var buildings: [CampusBuilding] = []
    private(set) var selectedBuilding: CampusBuilding?
    private(set) var availabilities: [LevelAvailability] = []

    private let repository: any StudySpaceRepository
    private let viewLevelAvailability: ViewLevelAvailabilityUseCase
    private let settings: AppSettingsStore

    init(
        repository: any StudySpaceRepository,
        viewLevelAvailability: ViewLevelAvailabilityUseCase,
        settings: AppSettingsStore
    ) {
        self.repository = repository
        self.viewLevelAvailability = viewLevelAvailability
        self.settings = settings
    }

    var lastUpdatedAt: Date? {
        availabilities.first?.lastUpdatedAt
    }

    func refresh(now: Date) async {
        if state != .loaded {
            state = .loading
        }

        do {
            if buildings.isEmpty {
                buildings = try await repository.buildings()
            }
            if selectedBuilding == nil {
                selectedBuilding = buildings.first { $0.id == settings.lastBuildingID } ?? buildings.first
            }
            guard let building = selectedBuilding else {
                availabilities = []
                state = .loaded
                return
            }
            availabilities = try await viewLevelAvailability.execute(building: building, now: now)
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            state = .couldNotReach
        }
    }

    func select(building: CampusBuilding, now: Date) async {
        selectedBuilding = building
        settings.lastBuildingID = building.id
        availabilities = []
        state = .loading
        await refresh(now: now)
    }
}
