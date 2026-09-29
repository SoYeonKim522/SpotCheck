//
//  SpotCheckWidget.swift
//  SpotCheckWidget
//
//  Created by MACBOOK_PRO on 29/9/2026.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, text: "Nothing written yet")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: .now, text: readText()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        completion(Timeline(entries: [SimpleEntry(date: .now, text: readText())], policy: .never))
    }

    private func readText() -> String {
        guard let url = AppGroup.containerURL?.appending(path: "spike.txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Nothing written yet"
        }
        return text
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let text: String
}

struct SpotCheckWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.text)
    }
}

struct SpotCheckWidget: Widget {
    let kind: String = "SpotCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SpotCheckWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SpotCheck")
        .description("Shows what the app wrote to the App Group.")
    }
}

#Preview(as: .systemSmall) {
    SpotCheckWidget()
} timeline: {
    SimpleEntry(date: .now, text: "Written at 9:00:00 AM")
}
