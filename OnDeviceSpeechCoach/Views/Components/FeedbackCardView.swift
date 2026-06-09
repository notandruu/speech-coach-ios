import SwiftUI

struct FeedbackCardView: View {
    let feedback: SpeechFeedback

    private var icon: String {
        switch feedback.sentiment {
        case .positive: return "checkmark.circle.fill"
        case .neutral: return "info.circle.fill"
        case .negative: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch feedback.sentiment {
        case .positive: return .green
        case .neutral: return .blue
        case .negative: return .orange
        }
    }

    private var categoryLabel: String {
        feedback.category.rawValue.capitalized
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(feedback.message)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: 10) {
        ForEach(SpeechFeedback.previewSet) { f in
            FeedbackCardView(feedback: f)
        }
    }
    .padding()
}
