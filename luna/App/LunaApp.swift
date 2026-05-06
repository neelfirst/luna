import SwiftUI

@main
struct LunaApp: App {
    @StateObject private var store = CycleStore(
        calculator: CycleCalculator(),
        notificationScheduler: UserNotificationScheduler(),
        batchProcessor: LLMBatchProcessor(
            client: HTTPBackendBatchClient(endpoint: nil)
        )
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
