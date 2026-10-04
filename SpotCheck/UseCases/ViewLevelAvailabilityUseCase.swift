import Foundation

struct ViewLevelAvailabilityUseCase {
    let repository: any StudySpaceRepository

    func execute(buildingID: UUID, now: Date) async throws -> [LevelAvailability] {
        // TODO: read the levels, count the free seats on each, stamp every result with `now`
        []
    }
}

enum ViewLevelAvailabilityError: LocalizedError {
    case readDidNotArrive

    var errorDescription: String? {
        // TODO
        nil
    }

    var recoverySuggestion: String? {
        // TODO
        nil
    }
}
