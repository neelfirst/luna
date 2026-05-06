import Foundation
import UserNotifications

protocol CycleNotificationScheduling {
    func requestAuthorization() async throws -> Bool
    func reschedule(for snapshot: CycleSnapshot) async throws
}

struct UserNotificationScheduler: CycleNotificationScheduling {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.calendar = calendar
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func reschedule(for snapshot: CycleSnapshot) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [
            ReminderIdentifier.periodSoon,
            ReminderIdentifier.periodToday
        ])

        if let reminderDate = calendar.date(
            byAdding: .day,
            value: -1,
            to: snapshot.nextPeriodStart
        ) {
            try await schedule(
                identifier: ReminderIdentifier.periodSoon,
                title: "Period expected tomorrow",
                body: "Cycle day \(snapshot.cycleDay)",
                date: reminderDate
            )
        }

        try await schedule(
            identifier: ReminderIdentifier.periodToday,
            title: "Period expected today",
            body: "Open Luna to log or adjust the date.",
            date: snapshot.nextPeriodStart
        )
    }

    private func schedule(
        identifier: String,
        title: String,
        body: String,
        date: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }
}

private enum ReminderIdentifier {
    static let periodSoon = "luna.period.soon"
    static let periodToday = "luna.period.today"
}
