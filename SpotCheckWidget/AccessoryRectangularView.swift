import WidgetKit
import SwiftUI

struct AccessoryRectangularView: View {
    let entry: SeatEntry

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(.clear, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.presentation {
        case .signedOut:
            Text("Sign in to SpotCheck to see seats.")
        case .held(let hold):
            held(hold)
        case .levels(let snapshot):
            if let level = snapshot.emptiestLevel {
                emptiest(level, in: snapshot)
            }
        case .notRecent:
            VStack(alignment: .leading) {
                Text("Not recent")
                    .font(.headline)
                    .widgetAccentable()
                Text("Open SpotCheck to see the free seats now.")
            }
        case .empty:
            Text("No seat held. Open SpotCheck to find one.")
        }
    }

    private func held(_ hold: AvailabilitySnapshot.HeldSeat) -> some View {
        VStack(alignment: .leading) {
            Text("Seat \(hold.seatLabel) · Level \(hold.levelNumber)")
                .font(.headline)
                .widgetAccentable()
                .lineLimit(1)
            Text(hold.zoneName)
                .lineLimit(1)
            Text("\(Text(timerInterval: entry.date...hold.expiresAt, showsHours: true)) left")
                .monospacedDigit()
        }
    }

    private func emptiest(_ level: AvailabilitySnapshot.LevelCount, in snapshot: AvailabilitySnapshot) -> some View {
        VStack(alignment: .leading) {
            Text("Level \(level.number) · \(level.free) of \(level.total) free")
                .font(.headline)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Gauge(value: Double(level.free), in: 0...Double(max(level.total, 1))) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            Text("\(snapshot.buildingName) · \(Text(snapshot.readAt, style: .relative)) ago")
                .lineLimit(1)
        }
    }
}
