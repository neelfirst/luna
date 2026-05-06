import SwiftUI

struct LogInputView: View {
    @Binding var text: String
    var latestEntry: CycleLogEntry?
    var backendStatus: String?
    var save: () -> Void
    var flushBatch: () -> Void

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            toolbar

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .textInputAutocapitalization(.sentences)

                if text.isEmpty {
                    Text("Log anything")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxHeight: .infinity)

            footer
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(Color(.systemBackground))
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Text("Log")
                .font(.headline)

            Spacer()

            if let backendStatus {
                Text(backendStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: flushBatch) {
                Image(systemName: "icloud.and.arrow.up")
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("Send queued logs")

            Button(action: save) {
                Image(systemName: "checkmark")
                    .frame(width: 34, height: 34)
            }
            .disabled(!canSave)
            .accessibilityLabel("Save log")
        }
    }

    private var footer: some View {
        HStack {
            if let latestEntry {
                Text("Last: day \(latestEntry.cycleDay), \(latestEntry.phase.displayName)")
                    .lineLimit(1)
            } else {
                Text("No logs")
            }

            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
