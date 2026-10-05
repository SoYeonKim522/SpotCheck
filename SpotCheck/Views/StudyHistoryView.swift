import SwiftUI

struct StudyHistoryView: View {
    @Environment(StudyHistoryViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
                .task { await viewModel.refresh(now: .now) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .couldNotReach:
            ContentUnavailableView {
                Label("Couldn't reach SpotCheck", systemImage: "wifi.slash")
            } description: {
                Text("Check your connection, then try again.")
            } actions: {
                Button("Try again") {
                    Task { await viewModel.refresh(now: .now) }
                }
            }
        case .loaded where viewModel.holds.isEmpty:
            ContentUnavailableView(
                "No past check-ins yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Once a hold ends, you'll see it here.")
            )
        case .loaded:
            List {
                Section {
                    HStack {
                        Text("Study time this week")
                        Spacer()
                        Text(timeText(viewModel.studyTimeThisWeek))
                            .font(.headline)
                            .monospacedDigit()
                    }
                }

                Section("Past check-ins") {
                    ForEach(viewModel.holds) { hold in
                        HistoryRow(hold: hold)
                    }
                }
            }
            .refreshable { await viewModel.refresh(now: .now) }
        }
    }
}

private struct HistoryRow: View {
    let hold: SeatHold

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Seat \(hold.seatLabel)")
                    .fontWeight(.medium)
                Text("\(hold.zoneName) · Level \(hold.levelNumber) · \(hold.buildingName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(hold.checkIn.checkedInAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timeText(TimeInterval(hold.checkIn.minutesAtSeat * 60)))
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

private func timeText(_ interval: TimeInterval) -> String {
    Duration.seconds(interval).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
}
