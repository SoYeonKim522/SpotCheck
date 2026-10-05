import SwiftUI

struct SeatPickerView: View {
    @State private var viewModel: SeatPickerViewModel
    @State private var requiresPowerOutlet = false
    @State private var requiresComputer = false
    @State private var requiresPartition = false
    @State private var requiresWindow = false
    @State private var requiresSharedTable = false

    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 10)]

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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    summary
                    Divider()
                    legend
                    filters

                    if isFiltering && !hasMatchingSeat {
                        Text("No seat on this level has all of these. Turn a filter off to see more.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .card()

                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    Text(LastUpdated.text(viewModel.readAt, at: .now))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 8)
                }

                ForEach(viewModel.zones) { zone in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(zoneHeading(zone))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)

                        LazyVGrid(columns: columns, spacing: 10) {
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
                        .padding(16)
                        .card()
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
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
            .padding(2)
        }
        .scrollIndicators(.hidden)
    }

    private func filterChip(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn.wrappedValue ? Color.accentColor : .secondary)
                Text(title)
                    .foregroundStyle(isOn.wrappedValue ? Color.selectedText : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn.wrappedValue ? Color.accentColor.opacity(0.12) : .clear, in: .capsule)
            .overlay {
                Capsule().stroke(isOn.wrappedValue ? Color.accentColor : .secondary.opacity(0.4), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn.wrappedValue ? [.isToggle, .isSelected] : .isToggle)
    }

    private var legend: some View {
        HStack(spacing: 12) {
            legendKey(.green, "free")
            legendKey(.red, "taken")
            legendKey(.green, "your pick", isSelected: true)
            if isFiltering {
                legendKey(.gray.opacity(0.4), "filtered out")
            }
        }
        .font(.caption)
    }

    private func legendKey(_ colour: Color, _ label: String, isSelected: Bool = false) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(colour.opacity(0.5))
                .overlay { Circle().stroke(colour, lineWidth: 1.5) }
                .overlay { Circle().stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0) }
                .frame(width: 18, height: 18)
            Text(label)
        }
    }

    private func zoneHeading(_ zone: StudyZone) -> String {
        guard let noiseLevel = zone.noiseLevel else { return zone.name }
        return "\(zone.name) · \(noiseLevel.displayName)"
    }
}

private extension Color {
    static let selectedText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0x2D / 255, green: 0x4E / 255, blue: 0x76 / 255, alpha: 1)
    })
}

private extension View {
    func card() -> some View {
        background(.background, in: .rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(.primary, lineWidth: 2) }
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

    private var isMuted: Bool {
        state == .filteredOut
    }

    private var accessibilityName: String {
        state == .filteredOut && isMine ? "\(state.name), checked in" : state.name
    }

    var body: some View {
        Text(seat.label)
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(state == .filteredOut ? .secondary : .primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(state.tint.opacity(isMuted ? 0.2 : 0.5), in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(state.tint.opacity(isMuted ? 0.4 : 1), lineWidth: 1.5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
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
