//
//  LevelListView.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 12/9/2026.
//

import SwiftUI
import SwiftData

struct LevelListView: View {
    @State private var viewModel: LevelListViewModel

    private let repository: StudySpaceRepository
    private let occupant: OccupantIdentifier

    init(repository: StudySpaceRepository, occupant: OccupantIdentifier) {
        self.repository = repository
        self.occupant = occupant
        _viewModel = State(initialValue: LevelListViewModel(repository: repository))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Menu {
                    ForEach(viewModel.buildings) { building in
                        Button(building.name) { viewModel.select(building: building, now: .now) }
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

            List {
                Section {
                    ForEach(viewModel.availabilities, id: \.level) { availability in
                        NavigationLink(value: availability.level) {
                            LevelAvailabilityRow(availability: availability)
                        }
                    }
                } footer: {
                    footer
                }
            }
            .refreshable { viewModel.refresh(now: .now) }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: StudyLevel.self) { level in
            SeatPickerView(level: level, repository: repository, occupant: occupant)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.refresh(now: .now)
                } label: {
                    Label("Refresh availability", systemImage: "arrow.clockwise")
                }
            }
        }
        .onAppear { viewModel.refresh(now: .now) }
    }

    @ViewBuilder
    private var footer: some View {
        if let lastUpdatedAt = viewModel.lastUpdatedAt {
            Text("Last updated \(lastUpdatedAt.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))")
        } else {
            Text("No check-ins reported yet")
        }
    }
}

private struct LevelAvailabilityRow: View {
    let availability: LevelAvailability

    private var freeFraction: Double {
        availability.total == 0 ? 0 : Double(availability.free) / Double(availability.total)
    }

    private var isNearlyFull: Bool {
        freeFraction < 0.2
    }

    private var status: Color {
        freeFraction >= 0.5 ? .green : (isNearlyFull ? .red : .yellow)
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
                .foregroundStyle(isNearlyFull ? Color.red : .primary)
                .layoutPriority(1)
        }
        .padding(.vertical, 4)
    }
}

@MainActor
private func previewContainer() -> ModelContainer {
    let container = try! ModelContainer(
        for: CampusBuilding.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    try! SeedData.loadIfEmpty(into: container.mainContext, now: .now)
    return container
}

#Preview {
    let container = previewContainer()
    NavigationStack {
        LevelListView(
            repository: SwiftDataStudySpaceRepository(context: container.mainContext),
            occupant: OccupantIdentifier(value: "preview-occupant")
        )
    }
    .modelContainer(container)
}
