import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                privacySection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete all local data?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All Sessions", role: .destructive) {
                    deleteAllSessions()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all saved session scores from this device. It cannot be undone.")
            }
        }
    }

    private var privacySection: some View {
        Section {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy-First Design")
                        .font(.headline)
                    Text("Your voice recordings are processed entirely on this device. Raw audio is deleted immediately after scoring. No data is uploaded to any server.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)

            Label("No microphone data leaves this device", systemImage: "mic.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label("No analytics or tracking SDKs", systemImage: "eye.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Label("No network requests during scoring", systemImage: "wifi.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } header: {
            Text("Privacy")
        }
    }

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete All Local Data", systemImage: "trash")
            }

            if let error = deleteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Removes all session scores stored on this device. Microphone recordings are never saved by default.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            labelRow("Model", value: "\(ModelVersion.name) v\(ModelVersion.version)")
            labelRow("Input shape", value: "[\(ModelVersion.inputShape.bins) × \(ModelVersion.inputShape.frames)]")
            labelRow("Compute", value: "On-device (Neural Engine / CPU)")
            labelRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
        }
    }

    private func labelRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.subheadline)
    }

    private func deleteAllSessions() {
        let store = SessionStore(context: context)
        do {
            try store.deleteAll()
            deleteError = nil
        } catch {
            deleteError = "Could not delete sessions: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PersistenceController.preview.container)
}
