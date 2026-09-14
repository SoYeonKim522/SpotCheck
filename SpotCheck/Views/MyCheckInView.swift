//
//  MyCheckInView.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import SwiftUI

struct MyCheckInView: View {
    let viewModel: MyCheckInViewModel

    @Binding var isOnScreen: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingRelease = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            if let checkIn = viewModel.checkIn, let seat = checkIn.seat, checkIn.isActive(at: .now) {
                held(checkIn, seat, at: .now)
            } else {
                empty
            }
        }
        .navigationTitle("Your check-in")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh(now: .now)
            isOnScreen = true
        }
        .onDisappear { isOnScreen = false }
    }

    private func held(_ checkIn: SeatCheckIn, _ seat: StudySeat, at now: Date) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                HoldRing(fraction: remainingFraction(of: checkIn, at: now), lineWidth: 10)
                VStack(spacing: 2) {
                    Text(remainingDurationText(of: checkIn, at: now))
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
                Text("Seat \(seat.label)")
                    .font(.title2.weight(.medium))
                Text(placeHeading(seat))
                    .foregroundStyle(.secondary)
                Text("Checked in: \(checkIn.checkedInAt.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                Text("You can hold this seat for \(SeatHoldPolicy.maximumDurationText) max")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.extend(now: .now)
                } label: {
                    Text("Hold for another hour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    isConfirmingRelease = true
                } label: {
                    Text("Release seat")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .alert(
                    "Release \(seat.label)?",
                    isPresented: $isConfirmingRelease
                ) {
                    Button("Release seat", role: .destructive) {
                        viewModel.release(now: .now)
                        if viewModel.actionError == nil { dismiss() }
                    }
                    Button("Keep seat", role: .cancel) {}
                } message: {
                    Text("Someone else can claim it straight away.")
                }
            }
        }
        .padding(24)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Text("You don't hold a seat")
                .font(.title3.weight(.medium))

            if let error = viewModel.actionError {
                Text(error.recoverySuggestion ?? "")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Pick a level, then a free seat.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func placeHeading(_ seat: StudySeat) -> String {
        guard let zone = seat.zone, let level = zone.level, let building = level.building else {
            return ""
        }
        return "\(zone.name) · Level \(level.number) · \(building.name)"
    }
}
