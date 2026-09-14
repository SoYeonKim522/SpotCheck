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
    private let onCheckIn: () -> Void

    init(repository: StudySpaceRepository, occupant: OccupantIdentifier, onCheckIn: @escaping () -> Void) {
        self.repository = repository
        self.occupant = occupant
        self.onCheckIn = onCheckIn
        _viewModel = State(initialValue: LevelListViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if viewModel.buildings.isEmpty {
                ContentUnavailableView(
                    "No study spaces available",
                    systemImage: "building.2",
                    description: Text("SpotCheck has no buildings to show. Reopen the app to try again.")
                )
            } else {
                levels
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: StudyLevel.self) { level in
            SeatPickerView(level: level, repository: repository, occupant: occupant, onCheckIn: onCheckIn)
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

    private var levels: some View {
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
                    Text(LastUpdated.text(viewModel.lastUpdatedAt, at: .now))
                }
            }
            .refreshable { viewModel.refresh(now: .now) }
        }
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
            occupant: OccupantIdentifier(value: "preview-occupant"),
            onCheckIn: {}
        )
    }
    .modelContainer(container)
}
