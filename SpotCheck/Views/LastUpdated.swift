import Foundation

enum LastUpdated {
    static func text(_ moment: Date, at now: Date) -> String {
        guard now.timeIntervalSince(moment) >= 60 else { return "Last updated just now" }
        return "Last updated \(moment.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))"
    }
}
