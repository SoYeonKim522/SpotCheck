import SwiftUI

struct SeatReminderView: View {
    let reminder: SeatReminder

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your seat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(reminder.seatLabel)
                    .font(.system(size: 40, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Level \(reminder.levelNumber) · \(reminder.zoneName)")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(reminder.buildingName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(timerInterval: Date.now...max(reminder.expiresAt, .now), showsHours: false)
                    .font(.title.weight(.medium))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                Text("left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
