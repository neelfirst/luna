import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CycleStore

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                CycleSummaryView(
                    snapshot: store.snapshot,
                    profile: $store.profile,
                    notificationsEnabled: store.notificationsEnabled,
                    notificationStatus: store.notificationStatus,
                    enableNotifications: store.enableNotifications
                )
                .frame(height: proxy.size.height * 0.66)

                Divider()

                LogInputView(
                    text: $store.draftText,
                    latestEntry: store.entries.first,
                    backendStatus: store.backendStatus,
                    save: store.saveDraft,
                    flushBatch: store.flushBatch
                )
                .frame(maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            CycleStore(
                calculator: CycleCalculator(),
                notificationScheduler: UserNotificationScheduler(),
                batchProcessor: LLMBatchProcessor(
                    client: HTTPBackendBatchClient(endpoint: nil)
                )
            )
        )
}
