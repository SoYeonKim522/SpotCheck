//
//  LastUpdated.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation

enum LastUpdated {
    static func text(_ moment: Date?, at now: Date) -> String {
        guard let moment else { return "No check-ins reported yet" }
        guard now.timeIntervalSince(moment) >= 60 else { return "Last updated just now" }
        return "Last updated \(moment.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))"
    }
}
