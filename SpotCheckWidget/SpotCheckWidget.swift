import WidgetKit
import SwiftUI

struct SeatEntry: TimelineEntry {
    let date: Date
    let snapshot: AvailabilitySnapshot?
    let isSignedIn: Bool

    var hold: AvailabilitySnapshot.HeldSeat? {
        guard let hold = snapshot?.hold, hold.expiresAt > date else { return nil }
        return hold
    }

    var isRecent: Bool {
        snapshot?.isRecent(at: date) ?? false
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SeatEntry {
        SeatEntry(date: .now, snapshot: nil, isSignedIn: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SeatEntry) -> ()) {
        completion(currentEntry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SeatEntry>) -> ()) {
        completion(Timeline(entries: entries(at: .now), policy: .never))
    }

    private func currentEntry(at moment: Date) -> SeatEntry {
        entries(at: moment)[0]
    }

    private func entries(at moment: Date) -> [SeatEntry] {
        let snapshot = AvailabilitySnapshotStore().read()
        let isSignedIn = AppSettingsStore().isSignedIn
        let moments = [moment] + (snapshot?.displayChanges(from: moment) ?? [])
        return moments.map { SeatEntry(date: $0, snapshot: snapshot, isSignedIn: isSignedIn) }
    }
}

struct SpotCheckWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            // TODO: medium and accessoryRectangular layouts
            Text(entry.snapshot?.buildingName ?? "No seat held. Open SpotCheck to find one.")
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

private struct SmallWidgetView: View {
    let entry: SeatEntry

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(for: .widget) {
                entry.hold == nil ? Color(.systemBackground) : Color.holdGreen
            }
    }

    @ViewBuilder
    private var content: some View {
        if !entry.isSignedIn {
            message("Sign in to SpotCheck to see seats.")
        } else if let hold = entry.hold {
            held(hold)
        } else if let snapshot = entry.snapshot, let level = snapshot.emptiestLevel {
            if entry.isRecent {
                emptiest(level, in: snapshot)
            } else {
                notRecent(in: snapshot)
            }
        } else {
            message("No seat held. Open SpotCheck to find one.")
        }
    }

    private func held(_ hold: AvailabilitySnapshot.HeldSeat) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Your seat")
                .font(.caption)
            Text(hold.seatLabel)
                .font(.largeTitle.weight(.semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("Level \(hold.levelNumber) · \(hold.zoneName)")
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(timerInterval: entry.date...hold.expiresAt, showsHours: true)
                .font(.title3.weight(.medium))
                .monospacedDigit()
            Text("left")
                .font(.caption)
        }
        .foregroundStyle(Color.holdGreenText)
    }

    private func emptiest(_ level: AvailabilitySnapshot.LevelCount, in snapshot: AvailabilitySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snapshot.buildingName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Circle()
                .fill(level.fullness.fill)
                .overlay { Circle().stroke(level.fullness.edge, lineWidth: 1.5) }
                .frame(width: 22, height: 22)
            Text("Level \(level.number)")
                .font(.title3.weight(.semibold))
            Text("\(level.free) of \(level.total) free")
                .font(.subheadline)
                .monospacedDigit()
            Text("Updated \(Text(snapshot.readAt, style: .relative)) ago")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func notRecent(in snapshot: AvailabilitySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snapshot.buildingName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text("Not recent")
                .font(.title3.weight(.semibold))
            Text("Open SpotCheck to see the free seats now.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
    }
}

struct SpotCheckWidget: Widget {
    let kind: String = "SpotCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SpotCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SpotCheck")
        .description("Your held seat and the free seats in the building you last viewed.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
