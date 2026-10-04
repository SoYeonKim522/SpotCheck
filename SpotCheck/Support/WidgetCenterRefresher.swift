import WidgetKit

/// Asks WidgetKit to rebuild every widget timeline.
struct WidgetCenterRefresher: WidgetRefreshing {
    func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
