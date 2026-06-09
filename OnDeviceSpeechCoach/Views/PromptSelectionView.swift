import SwiftUI

struct PromptSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: PromptCategory? = nil

    private var filtered: [PracticePrompt] {
        guard let cat = selectedCategory else { return PracticePrompt.samples }
        return PracticePrompt.samples.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            List {
                categoryFilter
                ForEach(filtered) { prompt in
                    NavigationLink {
                        RecordingView(prompt: prompt)
                            .onDisappear { dismiss() }
                    } label: {
                        promptRow(prompt)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Choose a Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", selected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(PromptCategory.allCases, id: \.self) { cat in
                    filterChip(label: cat.rawValue.capitalized, selected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func filterChip(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func promptRow(_ prompt: PracticePrompt) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(prompt.title)
                    .font(.headline)
                Spacer()
                difficultyBadge(prompt.difficulty)
            }
            Text(prompt.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 12) {
                Label(prompt.category.rawValue.capitalized, systemImage: "tag")
                Label("~\(prompt.estimatedSeconds)s", systemImage: "timer")
                Label("\(prompt.wordCount) words", systemImage: "text.alignleft")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func difficultyBadge(_ level: PromptDifficulty) -> some View {
        Text(level.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(difficultyColor(level).opacity(0.15))
            .foregroundStyle(difficultyColor(level))
            .clipShape(Capsule())
    }

    private func difficultyColor(_ level: PromptDifficulty) -> Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

#Preview {
    PromptSelectionView()
}
