import WidgetKit
import SwiftUI

struct NovaMovilWidgetEntry: TimelineEntry {
    let date: Date
}

struct NovaMovilWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NovaMovilWidgetEntry {
        NovaMovilWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NovaMovilWidgetEntry) -> ()) {
        completion(NovaMovilWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NovaMovilWidgetEntry>) -> ()) {
        let entry = NovaMovilWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct NovaMovilWidgetView: View {
    var entry: NovaMovilWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Link(destination: URL(string: "nova://activate")!) {
                ZStack {
                    Circle().fill(.green.opacity(0.25))
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        case .accessoryRectangular:
            Link(destination: URL(string: "nova://activate")!) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.white)
                    Text("Activar emergencia").foregroundStyle(.white)
                    Spacer()
                }
                .padding(6)
                .background(Color(red: 16/255, green: 185/255, blue: 129/255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        default:
            Link(destination: URL(string: "nova://activate")!) {
                VStack {
                    Text("NovaMovil").font(.caption)
                    Text("Activar").bold()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.2))
            }
        }
    }
}

@main
struct NovaMovilWidget: Widget {
    let kind: String = "NovaMovilWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NovaMovilWidgetProvider()) { entry in
            NovaMovilWidgetView(entry: entry)
        }
        .configurationDisplayName("Emergencia Nova")
        .description("Activa tu emergencia rápidamente desde tu pantalla.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}
