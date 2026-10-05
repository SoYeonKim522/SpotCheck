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
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Study time this week")
                        Spacer()
                        Text(timeText(viewModel.studyTimeThisWeek))
                            .font(.headline)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .card(fill: .holdGreen)

                    Text("Past check-ins")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sectionGreen)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    VStack(spacing: 0) {
                        ForEach(viewModel.holds) { hold in
                            HistoryRow(hold: hold)
                            if hold.id != viewModel.holds.last?.id {
                                Divider().overlay(Color.dividerGreen)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .card()
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable { await viewModel.refresh(now: .now) }
        }
    }
}

private struct HistoryRow: View {
    let hold: SeatHold

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Seat")
                        .fontWeight(.medium)
                    Text(hold.seatLabel)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.tagGreenText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.tagGreenFill, in: .rect(cornerRadius: 8))
                }
                Text("\(hold.zoneName) · Level \(hold.levelNumber) · \(hold.buildingName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(hold.checkIn.checkedInAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timeText(TimeInterval(hold.checkIn.minutesAtSeat * 60)))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Color.holdGreenText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.holdGreen, in: .capsule)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}

private func timeText(_ interval: TimeInterval) -> String {
    Duration.seconds(interval)
        .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        .replacing(".", with: "")
}
