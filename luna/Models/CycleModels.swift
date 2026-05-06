import Foundation

enum CyclePhase: String, Codable, CaseIterable, Sendable {
    case menstruation
    case follicular
    case ovulation
    case luteal

    var displayName: String {
        switch self {
        case .menstruation:
            return "Period"
        case .follicular:
            return "Follicular"
        case .ovulation:
            return "Ovulation"
        case .luteal:
            return "Luteal"
        }
    }

    var shortSignal: String {
        switch self {
        case .menstruation:
            return "reset"
        case .follicular:
            return "rise"
        case .ovulation:
            return "peak"
        case .luteal:
            return "restore"
        }
    }
}

struct CycleProfile: Codable, Equatable, Sendable {
    var lastPeriodStart: Date
    var cycleLength: Int
    var periodLength: Int

    static func `default`(calendar: Calendar = .autoupdatingCurrent) -> CycleProfile {
        let today = calendar.startOfDay(for: Date())
        let seededStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        return CycleProfile(
            lastPeriodStart: seededStart,
            cycleLength: 28,
            periodLength: 5
        )
    }

    func normalized() -> CycleProfile {
        CycleProfile(
            lastPeriodStart: lastPeriodStart,
            cycleLength: min(max(cycleLength, 21), 45),
            periodLength: min(max(periodLength, 2), 10)
        )
    }
}

struct CycleSnapshot: Equatable, Sendable {
    var date: Date
    var cycleDay: Int
    var currentCycleStart: Date
    var nextPeriodStart: Date
    var daysUntilNextPeriod: Int
    var phase: CyclePhase
    var fertileWindowStartDay: Int
    var fertileWindowEndDay: Int
}

struct CycleLogEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var text: String
    var cycleDay: Int
    var phase: CyclePhase

    init(
        id: UUID = UUID(),
        createdAt: Date,
        text: String,
        cycleDay: Int,
        phase: CyclePhase
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.cycleDay = cycleDay
        self.phase = phase
    }
}
