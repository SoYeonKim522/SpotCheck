//
//  CheckInBar.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import SwiftUI

struct HoldRing: View {
    let fraction: Double
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(.green, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct CheckInBar: View {
    let checkIn: SeatCheckIn
    let now: Date
    let open: () -> Void
    let release: () -> Void

    @State private var isConfirmingRelease = false

    var body: some View {
        if let seat = checkIn.seat, checkIn.isActive(at: now) {
            HStack(spacing: 12) {
                Button(action: open) {
                    HStack(spacing: 12) {
                        HoldRing(fraction: remainingFraction(of: checkIn, at: now))
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(seatHeading(seat))
                                .font(.subheadline.weight(.medium))
                            Text(remainingText(of: checkIn, at: now))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                Button("Release") { isConfirmingRelease = true }
                    .buttonStyle(.bordered)
                    .alert(
                        "Release \(seat.label)?",
                        isPresented: $isConfirmingRelease
                    ) {
                        Button("Release seat", role: .destructive, action: release)
                        Button("Keep seat", role: .cancel) {}
                    } message: {
                        Text("Someone else can claim it straight away.")
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            .overlay(alignment: .top) { Divider() }
        }
    }

    private func seatHeading(_ seat: StudySeat) -> String {
        guard let zone = seat.zone, let level = zone.level else { return seat.label }
        return "\(seat.label) · L\(level.number) \(zone.name)"
    }
}

func remainingFraction(of checkIn: SeatCheckIn, at now: Date) -> Double {
    let span = checkIn.expiresAt.timeIntervalSince(checkIn.checkedInAt)
    guard span > 0 else { return 0 }
    return max(0, min(1, checkIn.expiresAt.timeIntervalSince(now) / span))
}

func remainingDurationText(of checkIn: SeatCheckIn, at now: Date) -> String {
    let remaining = max(0, checkIn.expiresAt.timeIntervalSince(now))
    let minutes = Int((remaining / 60).rounded(.up))
    guard minutes >= 60 else { return "\(minutes) min" }
    let hours = minutes / 60
    let rest = minutes % 60
    return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
}

func remainingText(of checkIn: SeatCheckIn, at now: Date) -> String {
    "\(remainingDurationText(of: checkIn, at: now)) left"
}
