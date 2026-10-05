import WidgetKit
import SwiftUI

struct MediumWidgetView: View {
    let entry: SeatEntry

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) { entry.background }
    }

    @ViewBuilder
    private var content: some View {
        switch entry.presentation {
        case .signedOut:
            WidgetMessage(text: "Sign in to SpotCheck to see seats.")
        case .held(let hold):
            held(hold)
        case .levels(let snapshot):
            levels(in: snapshot)
        case .notRecent(let snapshot):
            NotRecentNotice(buildingName: snapshot.buildingName)
        case .empty:
            WidgetMessage(text: "No seat held. Open SpotCheck to find one.")
        }
    }

    private func held(_ hold: AvailabilitySnapshot.HeldSeat) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your seat")
                    .font(.caption)
                Text(hold.seatLabel)
                    .font(.system(size: 44, weight: .semibold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("Level \(hold.levelNumber) · \(hold.zoneName)")
                    .font(.subheadline)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(timerInterval: entry.date...hold.expiresAt, showsHours: true)
                    .font(.title.weight(.medium))
                    .monospacedDigit()
                Text("left")
                    .font(.subheadline)
            }
        }
        .foregroundStyle(Color.holdGreenText)
    }

    private func levels(in snapshot: AvailabilitySnapshot) -> some View {
        let sorted = snapshot.levels.sorted { $0.number < $1.number }.prefix(6)
        let half = (sorted.count + 1) / 2

        return VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.buildingName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            HStack(alignment: .top, spacing: 20) {
                column(Array(sorted.prefix(half)))
                column(Array(sorted.dropFirst(half)))
            }
            Spacer(minLength: 0)
            UpdatedLabel(readAt: snapshot.readAt)
        }
    }

    private func column(_ levels: [AvailabilitySnapshot.LevelCount]) -> some View {
        VStack(spacing: 6) {
            ForEach(levels) { level in
                HStack(spacing: 8) {
                    FullnessDot(fullness: level.fullness, size: 14)
                    Text("L\(level.number)")
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 0)
                    Text("\(level.free)/\(level.total)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(level.fullness == .nearlyFull ? Color.nearlyFullText : .primary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Level \(level.number), \(level.free) of \(level.total) seats free")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
