//
//  SeatPickerView.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import SwiftUI
import SwiftData

struct SeatPickerView: View {
    @State private var viewModel: SeatPickerViewModel
    @State private var requiresPowerOutlet = false
    @State private var requiresComputer = false
    @State private var requiresPartition = false
    @State private var requiresWindow = false
    @State private var requiresSharedTable = false
    @State private var sheetHeight: CGFloat = 320

    init(
        level: StudyLevel,
        repository: StudySpaceRepository,
        occupant: OccupantIdentifier,
        onCheckIn: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: SeatPickerViewModel(
                level: level,
                repository: repository,
                occupant: occupant,
                now: .now,
                onCheckIn: onCheckIn
            )
        )
    }

    private let columns = [GridItem(.adaptive(minimum: 60), spacing: 8)]

    var body: some View {
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
                Text(LastUpdated.text(viewModel.availability.lastUpdatedAt, at: .now))
                    .frame(maxWidth: .infinity, alignment: .trailing)
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
        .navigationTitle("Level \(viewModel.level.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refresh(now: .now)
                } label: {
                    Label("Refresh availability", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(item: seatDetail) { seat in
            SeatDetailSheet(
                seat: seat,
                levelNumber: viewModel.level.number,
                checkIn: { viewModel.checkIn(to: seat, now: .now) }
            )
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
            .presentationDetents([.height(sheetHeight)])
            .alert(
                viewModel.checkInError?.errorDescription ?? "",
                isPresented: checkInFailed,
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(viewModel.checkInError?.recoverySuggestion ?? "") }
            )
        }
        .refreshable { viewModel.refresh(now: .now) }
        .onAppear { viewModel.refresh(now: .now) }
        .onChange(of: activeFilters) { releaseFilteredSelection() }
    }

    private var activeFilters: [Bool] {
        [requiresPowerOutlet, requiresComputer, requiresPartition, requiresWindow, requiresSharedTable]
    }

    private var isFiltering: Bool {
        activeFilters.contains(true)
    }

    private var checkInFailed: Binding<Bool> {
        Binding(
            get: { viewModel.checkInError != nil },
            set: { if !$0 { viewModel.clearCheckInError() } }
        )
    }

    private var seatDetail: Binding<StudySeat?> {
        Binding(
            get: { viewModel.selectedSeat },
            set: { if $0 == nil { viewModel.deselect() } }
        )
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
        Text("\(viewModel.availability.free) of \(viewModel.availability.total) seats free")
            .font(.headline)
            .monospacedDigit()
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterChip("Power outlet", isOn: $requiresPowerOutlet)
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
    let levelNumber: Int
    let checkIn: () -> Void

    private var features: [String] {
        var names: [String] = []
        if seat.isByWindow { names.append("By a window") }
        if seat.hasComputer { names.append("Computer") }
        if seat.hasPowerOutlet { names.append("Power outlet") }
        if seat.hasPartition { names.append("Partition") }
        if seat.isSharedTable { names.append("Shared table") }
        return names
    }

    private var holdDuration: String {
        SeatHoldPolicy.durationText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(seat.label)
                    .font(.largeTitle.bold())
                Text("\(seat.zone?.name ?? "") · Level \(levelNumber)")
                    .foregroundStyle(.secondary)
            }

            if !features.isEmpty {
                Text(features.joined(separator: " · "))
                    .font(.subheadline)
            }

            Text("Your hold lasts \(holdDuration), then the seat frees itself.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(action: checkIn) {
                Text("Check in to \(seat.label)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(24)
        .padding(.bottom, 16)
    }
}

@MainActor
private let seatPickerPreviewContainer: ModelContainer = {
    let container = try! ModelContainer(
        for: CampusBuilding.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    try! SeedData.loadIfEmpty(into: container.mainContext, now: .now)
    return container
}()

@MainActor
private func previewLevel() -> StudyLevel {
    let buildings = try! seatPickerPreviewContainer.mainContext.fetch(FetchDescriptor<CampusBuilding>())
    return buildings.first { $0.name == "Building 2" }!.levels.first { $0.number == 5 }!
}

#Preview {
    NavigationStack {
        SeatPickerView(
            level: previewLevel(),
            repository: SwiftDataStudySpaceRepository(context: seatPickerPreviewContainer.mainContext),
            occupant: OccupantIdentifier(value: "preview-occupant"),
            onCheckIn: {}
        )
    }
    .modelContainer(seatPickerPreviewContainer)
}
