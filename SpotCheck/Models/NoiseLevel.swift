//
//  NoiseLevel.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation

enum NoiseLevel: String, Codable, CaseIterable {
    case silent
    case quiet
    case collaborative

    var displayName: String {
        switch self {
        case .silent: "Silent"
        case .quiet: "Quiet"
        case .collaborative: "Collaborative"
        }
    }
}
