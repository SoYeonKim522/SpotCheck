import SwiftUI
import WidgetKit

struct RootView: View {
    @State private var status = "Nothing written yet"

    var body: some View {
        VStack(spacing: 16) {
            Text(status)
            Button("Write to App Group", action: write)
        }
        .padding()
    }

    private func write() {
        guard let url = AppGroup.containerURL?.appending(path: "spike.txt") else {
            status = "No App Group container"
            return
        }
        let text = "Written at \(Date.now.formatted(date: .omitted, time: .standard))"
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            status = text
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            status = error.localizedDescription
        }
    }
}

#Preview {
    RootView()
}
