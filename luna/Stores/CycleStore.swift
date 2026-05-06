import Foundation
import Combine

@MainActor
final class CycleStore: ObservableObject {
    @Published var profile: CycleProfile {
        didSet {
            saveProfile()
        }
    }
    @Published private(set) var entries: [CycleLogEntry]
    @Published var draftText = ""
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var notificationStatus: String?
    @Published private(set) var backendStatus: String?

    private let calculator: CycleCalculator
    private let notificationScheduler: CycleNotificationScheduling
    private let batchProcessor: LLMBatchProcessor
    private let defaults: UserDefaults
    private let profileKey = "luna.profile"
    private let entriesKey = "luna.entries"

    init(
        calculator: CycleCalculator,
        notificationScheduler: CycleNotificationScheduling,
        batchProcessor: LLMBatchProcessor,
        defaults: UserDefaults = .standard
    ) {
        self.calculator = calculator
        self.notificationScheduler = notificationScheduler
        self.batchProcessor = batchProcessor
        self.defaults = defaults
        self.profile = (Self.load(
            CycleProfile.self,
            key: profileKey,
            defaults: defaults
        ) ?? CycleProfile.default(calendar: calculator.calendar)).normalized()
        self.entries = Self.load(
            [CycleLogEntry].self,
            key: entriesKey,
            defaults: defaults
        ) ?? []
    }

    var snapshot: CycleSnapshot {
        calculator.snapshot(profile: profile)
    }

    func saveDraft() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return
        }

        let entry = calculator.makeEntry(text: trimmedText, profile: profile)
        entries.insert(entry, at: 0)
        draftText = ""
        saveEntries()
        backendStatus = "Queued"

        Task {
            await batchProcessor.enqueue(entry)
        }
    }

    func enableNotifications() {
        Task {
            do {
                let allowed = try await notificationScheduler.requestAuthorization()
                notificationsEnabled = allowed
                notificationStatus = allowed ? "On" : "Denied"

                if allowed {
                    try await notificationScheduler.reschedule(for: snapshot)
                }
            } catch {
                notificationStatus = error.localizedDescription
            }
        }
    }

    func flushBatch() {
        Task {
            do {
                let response = try await batchProcessor.flush(profile: profile)
                backendStatus = "Sent \(response.acceptedCount)"
            } catch {
                backendStatus = error.localizedDescription
            }
        }
    }

    private func saveProfile() {
        Self.save(profile, key: profileKey, defaults: defaults)
    }

    private func saveEntries() {
        Self.save(entries, key: entriesKey, defaults: defaults)
    }

    private static func load<T: Decodable>(
        _ type: T.Type,
        key: String,
        defaults: UserDefaults
    ) -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? decoder.decode(type, from: data)
    }

    private static func save<T: Encodable>(
        _ value: T,
        key: String,
        defaults: UserDefaults
    ) {
        guard let data = try? encoder.encode(value) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
