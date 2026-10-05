import SwiftUI

extension Color {
    static let holdGreen = Color(red: 0x8E / 255, green: 0xCB / 255, blue: 0x8A / 255)
    static let holdGreenEdge = Color(red: 0x8A / 255, green: 0xB3 / 255, blue: 0x81 / 255)
    static let holdGreenText = Color(red: 0x17 / 255, green: 0x34 / 255, blue: 0x17 / 255)
    static let fillingUpYellow = Color(red: 0xF0 / 255, green: 0xCC / 255, blue: 0x78 / 255)
    static let fillingUpYellowEdge = Color(red: 0xD5 / 255, green: 0xB9 / 255, blue: 0x72 / 255)
    static let nearlyFullRed = Color(red: 0xE0 / 255, green: 0x93 / 255, blue: 0x8E / 255)
    static let nearlyFullRedEdge = Color(red: 0xBC / 255, green: 0x7C / 255, blue: 0x77 / 255)
    static let nearlyFullText = Color(red: 0xC0 / 255, green: 0x4A / 255, blue: 0x4A / 255)
    static let sectionGreen = Color(red: 0x5F / 255, green: 0x89 / 255, blue: 0x53 / 255)
    static let tagGreenFill = Color(red: 0xF2 / 255, green: 0xF7 / 255, blue: 0xF0 / 255)
    static let tagGreenText = Color(red: 0x4E / 255, green: 0x7A / 255, blue: 0x42 / 255)
    static let dividerGreen = Color(red: 0xE9 / 255, green: 0xF1 / 255, blue: 0xE6 / 255)
    static let releaseRed = Color(red: 0xC0 / 255, green: 0x45 / 255, blue: 0x3F / 255)
}

extension LevelFullness {
    var fill: Color {
        switch self {
        case .plenty: .holdGreen
        case .fillingUp: .fillingUpYellow
        case .nearlyFull: .nearlyFullRed
        }
    }

    var edge: Color {
        switch self {
        case .plenty: .holdGreenEdge
        case .fillingUp: .fillingUpYellowEdge
        case .nearlyFull: .nearlyFullRedEdge
        }
    }
}
