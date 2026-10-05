import SwiftUI

struct LevelListView: View {
    @Environment(AuthSession.self) private var session
    @Environment(LevelListViewModel.self) private var viewModel
    @Environment(MyCheckInViewModel.self) private var myCheckIn

    @State private var isConfirmingSignOut = false

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
            .alert(
                "Sign out while holding \(myCheckIn.hold?.seatLabel ?? "a seat")?",
                isPresented: $isConfirmingSignOut
            ) {
                Button("Sign out", role: .destructive) {
                    Task { await session.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Others can't use it until your hold ends. You can release it first on the My check-in tab.")
            }
            .navigationDestination(for: LevelAvailability.self) { availability in
                SeatPickerView(viewModel: makeSeatPickerViewModel(availability))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign out") {
                        if myCheckIn.hold == nil {
                            Task { await session.signOut() }
                        } else {
                            isConfirmingSignOut = true
                        }
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
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.subheadline)
                }
            }
            .foregroundStyle(.primary)

            Text(viewModel.selectedBuilding?.address ?? "")
                .font(.subheadline.italic())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.availabilities) { availability in
                    NavigationLink(value: availability) {
                        LevelAvailabilityRow(availability: availability)
                            .padding(.horizontal, 16)
                            .background(.background, in: .rect(cornerRadius: 24))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.primary, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }

                if let lastUpdatedAt = viewModel.lastUpdatedAt {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text(LastUpdated.text(lastUpdatedAt, at: .now))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await viewModel.refresh(now: .now) }
    }
}

private struct LevelAvailabilityRow: View {
    let availability: LevelAvailability

    private var status: Color {
        switch availability.fullness {
        case .plenty: .holdGreen
        case .fillingUp: .fillingUpYellow
        case .nearlyFull: .nearlyFullRed
        }
    }

    private var dot: (fill: Color, edge: Color) {
        switch availability.fullness {
        case .plenty: (.holdGreen, .holdGreenEdge)
        case .fillingUp: (.fillingUpYellow, .fillingUpYellowEdge)
        case .nearlyFull: (.nearlyFullRed, .nearlyFullRedEdge)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(dot.fill)
                .overlay { Circle().stroke(dot.edge, lineWidth: 1.5) }
                .frame(width: 22, height: 22)

            Text("L\(availability.level.number)")
                .fontWeight(.medium)
                .frame(width: 32, alignment: .leading)

            Gauge(
                value: Double(availability.free),
                in: 0...Double(max(availability.total, 1))
            ) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(status)

            Text("\(availability.free)/\(availability.total)")
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(availability.fullness == .nearlyFull ? Color.nearlyFullText : .primary)
                .layoutPriority(1)
        }
        .padding(.vertical, 18)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(availability.level.number), \(availability.free) of \(availability.total) seats free")
    }
}
