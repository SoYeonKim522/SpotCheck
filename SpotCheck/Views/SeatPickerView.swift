import SwiftUI

struct SeatPickerView: View {
    @State private var viewModel: SeatPickerViewModel
    @State private var requiresPowerOutlet = false
    @State private var requiresComputer = false
    @State private var requiresPartition = false
    @State private var requiresWindow = false
    @State private var requiresSharedTable = false

    private let columns = [GridItem(.adaptive(minimum: 60), spacing: 8)]

    init(viewModel: SeatPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.couldNotReach {
                ContentUnavailableView {
                    Label("Couldn't reach SpotCheck", systemImage: "wifi.slash")
                } description: {
                    Text("Check your connection, then try again.")
                } actions: {
                    Button("Try again") {
                        Task { await viewModel.refresh(now: .now) }
                    }
                }
            } else if viewModel.zones.isEmpty {
                ContentUnavailableView(
                    "No seats listed",
                    systemImage: "chair.lounge",
                    description: Text("Level \(viewModel.level.number) has no study seats to show.")
                )
            } else {
                seats
            }
        }
        .navigationTitle("Level \(viewModel.level.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh(now: .now) }
                } label: {
                    Label("Refresh availability", systemImage: "arrow.clockwise")
                }
            }
        }
        .task { await viewModel.refresh(now: .now) }
        .onChange(of: activeFilters) { releaseFilteredSelection() }
    }

    private var seats: some View {
        List {
            Section {
                summary
                legend
                filters

                if isFiltering && !hasMatchingSeat {
                    Text("No seat on this level has all of these. Turn a filter off to see more.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(LastUpdated.text(viewModel.readAt, at: context.date))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            ForEach(viewModel.zones) { zone in
                Section {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.seats(in: zone)) { seat in
                            let state = state(of: seat)
                            Button {
                                viewModel.select(seat)
                            } label: {
                                SeatChip(
                                    seat: seat,
                                    state: state,
                                    isMine: viewModel.isHeldByMe(seat),
                                    isSelected: viewModel.selectedSeat == seat
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(state != .free)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(zoneHeading(zone))
                }
            }
        }
        .refreshable { await viewModel.refresh(now: .now) }
    }

    private var activeFilters: [Bool] {
        [requiresPowerOutlet, requiresComputer, requiresPartition, requiresWindow, requiresSharedTable]
    }

    private var isFiltering: Bool {
        activeFilters.contains(true)
    }

    private func state(of seat: StudySeat) -> SeatChipState {
        if !matchesFilters(seat) { return .filteredOut }
        if viewModel.isHeldByMe(seat) { return .mine }
        return viewModel.isFree(seat) ? .free : .taken
    }

    private var hasMatchingSeat: Bool {
        viewModel.zones.contains { zone in
            viewModel.seats(in: zone).contains(where: matchesFilters)
        }
    }

    private func matchesFilters(_ seat: StudySeat) -> Bool {
        (!requiresPowerOutlet || seat.hasPowerOutlet)
            && (!requiresComputer || seat.hasComputer)
            && (!requiresPartition || seat.hasPartition)
            && (!requiresWindow || seat.isByWindow)
            && (!requiresSharedTable || seat.isSharedTable)
    }

    private func releaseFilteredSelection() {
        if let selectedSeat = viewModel.selectedSeat, !matchesFilters(selectedSeat) {
            viewModel.deselect()
        }
    }

    private var summary: some View {
        Text("\(viewModel.freeCount) of \(viewModel.totalCount) seats free")
            .font(.headline)
            .monospacedDigit()
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterChip("Power", isOn: $requiresPowerOutlet)
                filterChip("Computer", isOn: $requiresComputer)
                filterChip("Partition", isOn: $requiresPartition)
                filterChip("Window", isOn: $requiresWindow)
                filterChip("Shared table", isOn: $requiresSharedTable)
            }
        }
    }

    @ViewBuilder
    private func filterChip(_ title: String, isOn: Binding<Bool>) -> some View {
        let chip = Toggle(isOn: isOn) {
            HStack(spacing: 6) {
                if isOn.wrappedValue {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                }
                Text(title)
            }
        }
        .toggleStyle(.button)
        .buttonBorderShape(.capsule)

        if isOn.wrappedValue {
            chip.buttonStyle(.borderedProminent)
        } else {
            chip.buttonStyle(.bordered)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendKey(.green, "free")
            legendKey(.red, "taken")
            legendKey(.green, "your pick", isSelected: true)
            if isFiltering {
                legendKey(.gray, "filtered out")
            }
        }
        .font(.caption)
    }

    private func legendKey(_ colour: Color, _ label: String, isSelected: Bool = false) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(colour.opacity(0.35))
                .frame(width: 18, height: 18)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0)
                }
            Text(label)
        }
    }

    private func zoneHeading(_ zone: StudyZone) -> String {
        guard let noiseLevel = zone.noiseLevel else { return zone.name }
        return "\(zone.name) · \(noiseLevel.displayName)"
    }
}

private enum SeatChipState {
    case free
    case taken
    case mine
    case filteredOut

    var tint: Color {
        switch self {
        case .free, .mine: .green
        case .taken: .red
        case .filteredOut: .gray
        }
    }

    var name: String {
        switch self {
        case .free: "free"
        case .taken: "taken"
        case .mine: "checked in"
        case .filteredOut: "filtered out"
        }
    }
}

private struct SeatChip: View {
    let seat: StudySeat
    let state: SeatChipState
    let isMine: Bool
    let isSelected: Bool

    private var accessibilityName: String {
        state == .filteredOut && isMine ? "\(state.name), checked in" : state.name
    }

    var body: some View {
        Text(seat.label)
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(state == .filteredOut ? .secondary : .primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(state.tint.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: isSelected || isMine ? 3 : 0)
            }
            .accessibilityLabel("Seat \(seat.label), \(accessibilityName)")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
