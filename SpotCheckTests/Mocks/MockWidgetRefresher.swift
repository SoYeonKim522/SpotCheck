@testable import SpotCheck

final class MockWidgetRefresher: WidgetRefreshing {
    private(set) var reloadCount = 0

    func reloadAll() {
        reloadCount += 1
    }
}
