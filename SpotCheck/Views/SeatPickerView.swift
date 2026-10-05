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
        .sheet(item: seatDetail) { seat in
            SeatDetailSheet(
                seat: seat,
                zoneName: viewModel.zoneName(of: seat),
                levelNumber: viewModel.level.number,
                message: viewModel.checkInMessage,
                isCheckingIn: viewModel.isCheckingIn,
                checkIn: { Task { await viewModel.checkIn(to: seat, now: .now) } }
            )
        }
        .task { await viewModel.refresh(now: .now) }
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
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    Text(LastUpdated.text(viewModel.readAt, at: .now))
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

    private var isFiltering: Bool {
        [requiresPowerOutlet, requiresComputer, requiresPartition, requiresWindow, requiresSharedTable].contains(true)
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

    private var seatDetail: Binding<StudySeat?> {
        Binding(
            get: { viewModel.selectedSeat },
            set: { if $0 == nil { viewModel.deselect() } }
        )
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

private struct SeatDetailSheet: View {
    let seat: StudySeat
    let zoneName: String
    let levelNumber: Int
    let message: String?
    let isCheckingIn: Bool
    let checkIn: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var height: CGFloat = 320

    private var features: [(name: String, symbol: String)] {
        var features: [(String, String)] = []
        if seat.isByWindow { features.append(("By a window", "window.casement")) }
        if seat.hasComputer { features.append(("Computer", "desktopcomputer")) }
        if seat.hasPowerOutlet { features.append(("Power outlet", "powerplug")) }
        if seat.hasPartition { features.append(("Partition", "rectangle.split.2x1")) }
        if seat.isSharedTable { features.append(("Shared table", "person.2")) }
        return features
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(seat.label)
                        .font(.largeTitle.bold())
                    Text("\(zoneName) · Level \(levelNumber)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(.quaternary, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            if !features.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(features, id: \.name) { feature in
                            Label(feature.name, systemImage: feature.symbol)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .overlay { Capsule().stroke(.primary, lineWidth: 2) }
                        }
                    }
                    .padding(2)
                }
                .scrollIndicators(.hidden)
            }

            Text("Your seat will be held for \(SeatHoldPolicy.durationText), then released automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            Button(action: checkIn) {
                Group {
                    if isCheckingIn {
                        ProgressView()
                    } else {
                        Text("Check in to \(seat.label)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(.green.opacity(0.5), in: .capsule)
                .overlay { Capsule().stroke(.primary, lineWidth: 2) }
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(isCheckingIn)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding([.horizontal, .top], 24)
        .onGeometryChange(for: CGFloat.self) { $0.size.height + $0.safeAreaInsets.bottom } action: {
            height = $0
        }
        .presentationDetents([.height(height)])
    }
}
