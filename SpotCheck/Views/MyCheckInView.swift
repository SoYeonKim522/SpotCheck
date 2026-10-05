import SwiftUI

struct MyCheckInView: View {
    @Environment(MyCheckInViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My check-in")
                .navigationBarTitleDisplayMode(.inline)
                .task { await viewModel.refresh(now: .now) }
        }
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
        case .loaded:
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                if let hold = viewModel.hold, hold.checkIn.isActive(at: .now) {
                    held(hold, at: .now)
                } else {
                    ContentUnavailableView(
                        "You aren't holding a seat",
                        systemImage: "chair.lounge",
                        description: Text("Find one on the level list.")
                    )
                }
            }
        }
    }

    private func held(_ hold: SeatHold, at now: Date) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                HoldRing(fraction: remainingFraction(of: hold.checkIn, at: now), lineWidth: 10)
                VStack(spacing: 2) {
                    Text(remainingDurationText(of: hold.checkIn, at: now))
                        .font(.system(size: 40, weight: .medium))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 24)
                    Text("left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)

            VStack(spacing: 4) {
                Text("Seat \(hold.seatLabel)")
                    .font(.title2.weight(.medium))
                Text("\(hold.zoneName) · Level \(hold.levelNumber) · \(hold.buildingName)")
                    .foregroundStyle(.secondary)
                Text("Checked in: \(hold.checkIn.checkedInAt.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                Text("You can hold this seat for \(SeatHoldPolicy.maximumDurationText) max")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.extend(now: .now) }
                } label: {
                    Text("Hold for another hour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isWorking)

                Button(role: .destructive) {
                    viewModel.askToRelease()
                } label: {
                    Text("Release seat")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isWorking)
            }
        }
        .padding(24)
    }
}
