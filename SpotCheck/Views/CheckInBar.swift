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
    static let releaseRed = Color(red: 0xC0 / 255, green: 0x45 / 255, blue: 0x3F / 255)
}

extension View {
    func card() -> some View {
        background(.background, in: .rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(.primary, lineWidth: 2) }
    }
}

struct HoldRing: View {
    let fraction: Double
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.holdGreen, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct CheckInBar: View {
    let hold: SeatHold
    let open: () -> Void
    let release: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            HStack(spacing: 12) {
                Button(action: open) {
                    HStack(spacing: 12) {
                        HoldRing(fraction: remainingFraction(of: hold.checkIn, at: .now))
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(hold.seatLabel) · L\(hold.levelNumber) \(hold.zoneName)")
                                .font(.subheadline.weight(.medium))
                            Text(remainingText(of: hold.checkIn, at: .now))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Button("Release", action: release)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
        }
    }
}

func remainingFraction(of checkIn: SeatCheckIn, at now: Date) -> Double {
    let span = checkIn.expiresAt.timeIntervalSince(checkIn.checkedInAt)
    guard span > 0 else { return 0 }
    return max(0, min(1, checkIn.expiresAt.timeIntervalSince(now) / span))
}

func remainingDurationText(of checkIn: SeatCheckIn, at now: Date) -> String {
    let remaining = max(0, checkIn.expiresAt.timeIntervalSince(now))
    let minutes = Int((remaining / 60).rounded(.up))
    guard minutes >= 60 else { return "\(minutes) min" }
    let hours = minutes / 60
    let rest = minutes % 60
    return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
}

func remainingText(of checkIn: SeatCheckIn, at now: Date) -> String {
    "\(remainingDurationText(of: checkIn, at: now)) left"
}
