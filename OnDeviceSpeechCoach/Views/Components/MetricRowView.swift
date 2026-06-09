import SwiftUI

struct MetricRowView: View {
    let label: String
    let value: String
    var systemImage: String? = nil

    var body: some View {
        HStack {
            if let icon = systemImage {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.subheadline)
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        MetricRowView(label: "Words per minute", value: "145 WPM", systemImage: "speedometer")
        MetricRowView(label: "Duration", value: "28.5 s", systemImage: "timer")
        MetricRowView(label: "Pauses", value: "3", systemImage: "pause.circle")
    }
}
