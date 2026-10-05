import SwiftUI

extension View {
    func card(fill: Color = Color(.systemBackground)) -> some View {
        background(fill, in: .rect(cornerRadius: 24))
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
