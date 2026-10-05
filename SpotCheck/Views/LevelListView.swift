import SwiftUI

struct LevelListView: View {
    @Environment(AuthSession.self) private var session
    @Environment(LevelListViewModel.self) private var viewModel

    let makeSeatPickerViewModel: (LevelAvailability) -> SeatPickerViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if !viewModel.buildings.isEmpty {
                    buildingHeader
                }
                content
            }
            .task { await viewModel.refresh(now: .now) }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LevelAvailability.self) { availability in
                SeatPickerView(viewModel: makeSeatPickerViewModel(availability))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign out") {
                        Task { await session.signOut() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh(now: .now) }
                    } label: {
                        Label("Refresh availability", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    private var buildingHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Menu {
                ForEach(viewModel.buildings) { building in
                    Button(building.name) {
                        Task { await viewModel.select(building: building, now: .now) }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.selectedBuilding?.name ?? "SpotCheck")
                        .font(.largeTitle.bold())
                    Image(systemName: "chevron.down")
                        .font(.headline)
                }
            }
            .foregroundStyle(.primary)

            Text(viewModel.selectedBuilding?.address ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
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
        case .loaded where viewModel.buildings.isEmpty:
            ContentUnavailableView(
                "No study spaces available",
                systemImage: "building.2",
                description: Text("SpotCheck has no buildings to show yet.")
            )
        case .loaded where viewModel.availabilities.isEmpty:
            ContentUnavailableView(
                "No levels listed",
                systemImage: "square.stack.3d.up.slash",
                description: Text("This building has no study levels to show.")
            )
        case .loaded:
            levels
        }
    }

    private var levels: some View {
        List {
            Section {
                ForEach(viewModel.availabilities) { availability in
                    NavigationLink(value: availability) {
                        LevelAvailabilityRow(availability: availability)
                    }
                }
            } footer: {
                if let lastUpdatedAt = viewModel.lastUpdatedAt {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(LastUpdated.text(lastUpdatedAt, at: context.date))
                    }
                }
            }
        }
        .refreshable { await viewModel.refresh(now: .now) }
    }
}

private struct LevelAvailabilityRow: View {
    let availability: LevelAvailability

    private var status: Color {
        switch availability.fullness {
        case .plenty: .green
        case .fillingUp: .yellow
        case .nearlyFull: .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(status)
                .frame(width: 14, height: 14)

            Text("L\(availability.level.number)")
                .fontWeight(.medium)

            ProgressView(
                value: Double(availability.total - availability.free),
                total: Double(max(availability.total, 1))
            )
            .tint(status)

            Text("\(availability.free)/\(availability.total)")
                .monospacedDigit()
                .foregroundStyle(availability.fullness == .nearlyFull ? Color.red : .primary)
                .layoutPriority(1)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(availability.level.number), \(availability.free) of \(availability.total) seats free")
    }
}
