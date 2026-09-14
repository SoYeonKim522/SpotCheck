//
//  OccupantIdentifier.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation

/// Identifies a person using a seat without revealing who they are.
///
/// Campus buildings are open to everyone, so the person may not be a student.
/// The app only needs to tell different check-ins apart, not know who the person is.
struct OccupantIdentifier: Hashable, Codable {
    let value: String
}
