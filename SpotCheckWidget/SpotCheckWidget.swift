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

    var presentation: Presentation {
        if !isSignedIn { return .signedOut }
        if let hold { return .held(hold) }
        guard let snapshot, !snapshot.levels.isEmpty else { return .empty }
        return snapshot.isRecent(at: date) ? .levels(snapshot) : .notRecent(snapshot)
    }

    var background: Color {
        if case .held = presentation { Color.holdGreen } else { Color(.systemBackground) }
    }

    enum Presentation {
        case signedOut
        case held(AvailabilitySnapshot.HeldSeat)
        case levels(AvailabilitySnapshot)
        case notRecent(AvailabilitySnapshot)
        case empty
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
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

private struct SmallWidgetView: View {
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
            if let level = snapshot.emptiestLevel {
                emptiest(level, in: snapshot)
            }
        case .notRecent(let snapshot):
            NotRecentNotice(buildingName: snapshot.buildingName)
        case .empty:
            WidgetMessage(text: "No seat held. Open SpotCheck to find one.")
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
            Text("\(Text(timerInterval: entry.date...hold.expiresAt, showsHours: true).font(.title2.weight(.medium)).monospacedDigit()) \(Text("left").font(.caption))")
                .lineLimit(1)
            HoldProgress(hold: hold)
                .padding(.top, 4)
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
            FullnessDot(fullness: level.fullness, size: 22)
            Text("Level \(level.number)")
                .font(.title3.weight(.semibold))
            Text("\(level.free) of \(level.total) free")
                .font(.subheadline)
                .monospacedDigit()
            UpdatedLabel(readAt: snapshot.readAt)
        }
    }
}

struct HoldProgress: View {
    let hold: AvailabilitySnapshot.HeldSeat

    var body: some View {
        ProgressView(timerInterval: hold.checkedInAt...hold.expiresAt, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(Color.holdGreenText)
    }
}

struct WidgetMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
    }
}

struct NotRecentNotice: View {
    let buildingName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(buildingName)
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
}

struct UpdatedLabel: View {
    let readAt: Date

    var body: some View {
        Text("Updated \(Text(readAt, style: .relative)) ago")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct FullnessDot: View {
    let fullness: LevelFullness
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(fullness.fill)
            .overlay { Circle().stroke(fullness.edge, lineWidth: 1.5) }
            .frame(width: size, height: size)
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
