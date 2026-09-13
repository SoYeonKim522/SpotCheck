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
    @State private var requiresPartition = false
    @State private var sheetHeight: CGFloat = 320

    init(level: StudyLevel, repository: StudySpaceRepository, occupant: OccupantIdentifier) {
        _viewModel = State(
            initialValue: SeatPickerViewModel(
                level: level,
                repository: repository,
                occupant: occupant,
                now: .now
            )
        )
    }

    private let columns = [GridItem(.adaptive(minimum: 60), spacing: 8)]

    var body: some View {
        List {
            Section {
                summary
                legend
                Toggle("Power outlet", isOn: $requiresPowerOutlet)
                Toggle("Partition", isOn: $requiresPartition)
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
                error: viewModel.checkInError,
                checkIn: { viewModel.checkIn(to: seat, now: .now) }
            )
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
            .presentationDetents([.height(sheetHeight)])
        }
        .refreshable { viewModel.refresh(now: .now) }
        .onAppear { viewModel.refresh(now: .now) }
        .onChange(of: requiresPowerOutlet) { releaseFilteredSelection() }
        .onChange(of: requiresPartition) { releaseFilteredSelection() }
    }

    private var isFiltering: Bool {
        requiresPowerOutlet || requiresPartition
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

    private func matchesFilters(_ seat: StudySeat) -> Bool {
        (!requiresPowerOutlet || seat.hasPowerOutlet) && (!requiresPartition || seat.hasPartition)
    }

    private func releaseFilteredSelection() {
        if let selectedSeat = viewModel.selectedSeat, !matchesFilters(selectedSeat) {
            viewModel.deselect()
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(viewModel.availability.free) of \(viewModel.availability.total) seats free")
                .font(.headline)
                .monospacedDigit()

            Text(LastUpdated.text(viewModel.availability.lastUpdatedAt, at: .now))
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
    let error: CheckIntoSeatError?
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
        Duration.seconds(SeatHoldPolicy.duration)
            .formatted(.units(allowed: [.hours, .minutes], width: .wide))
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

            if let error {
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.errorDescription ?? "")
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    Text(error.recoverySuggestion ?? "")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            Button(action: checkIn) {
                Text("Check in to \(seat.label)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Your hold lasts \(holdDuration), then the seat frees itself.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
            occupant: OccupantIdentifier(value: "preview-occupant")
        )
    }
    .modelContainer(seatPickerPreviewContainer)
}
