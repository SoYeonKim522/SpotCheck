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
                            Button {
                                viewModel.select(seat)
                            } label: {
                                SeatChip(
                                    seat: seat,
                                    isFree: viewModel.isFree(seat),
                                    isSelected: viewModel.selectedSeat == seat,
                                    matchesFilters: matchesFilters(seat)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!viewModel.isFree(seat) || !matchesFilters(seat))
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
        .refreshable { viewModel.refresh(now: .now) }
        .onAppear { viewModel.refresh(now: .now) }
        .onChange(of: requiresPowerOutlet) { releaseFilteredSelection() }
        .onChange(of: requiresPartition) { releaseFilteredSelection() }
    }

    private var isFiltering: Bool {
        requiresPowerOutlet || requiresPartition
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

            if let lastUpdatedAt = viewModel.availability.lastUpdatedAt {
                Text("Last updated \(lastUpdatedAt.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No check-ins reported yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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

private struct SeatChip: View {
    let seat: StudySeat
    let isFree: Bool
    let isSelected: Bool
    let matchesFilters: Bool

    private var tint: Color {
        guard matchesFilters else { return .gray }
        return isFree ? .green : .red
    }

    private var state: String {
        guard matchesFilters else { return "filtered out" }
        return isFree ? "free" : "taken"
    }

    var body: some View {
        Text(seat.label)
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(matchesFilters ? .primary : .secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(tint.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: isSelected ? 3 : 0)
            }
            .accessibilityLabel("Seat \(seat.label), \(state)")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
