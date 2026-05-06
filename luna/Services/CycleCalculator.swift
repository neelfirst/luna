import Foundation

struct CycleCalculator: Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func snapshot(on date: Date = Date(), profile rawProfile: CycleProfile) -> CycleSnapshot {
        let profile = rawProfile.normalized()
        let cycleLength = profile.cycleLength
        let start = calendar.startOfDay(for: profile.lastPeriodStart)
        let today = calendar.startOfDay(for: date)
        let rawOffset = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        let normalizedOffset = positiveModulo(rawOffset, cycleLength)
        let cycleDay = normalizedOffset + 1
        let currentCycleStart = calendar.date(
            byAdding: .day,
            value: rawOffset - normalizedOffset,
            to: start
        ) ?? start
        let nextPeriodStart = calendar.date(
            byAdding: .day,
            value: cycleLength,
            to: currentCycleStart
        ) ?? currentCycleStart
        let daysUntilNextPeriod = calendar.dateComponents(
            [.day],
            from: today,
            to: nextPeriodStart
        ).day ?? 0
        let ovulationDay = max(profile.periodLength + 1, cycleLength - 14)
        let fertileWindowStartDay = max(profile.periodLength + 1, ovulationDay - 5)
        let fertileWindowEndDay = min(cycleLength, ovulationDay + 1)

        return CycleSnapshot(
            date: today,
            cycleDay: cycleDay,
            currentCycleStart: currentCycleStart,
            nextPeriodStart: nextPeriodStart,
            daysUntilNextPeriod: daysUntilNextPeriod,
            phase: phase(
                cycleDay: cycleDay,
                profile: profile,
                ovulationDay: ovulationDay
            ),
            fertileWindowStartDay: fertileWindowStartDay,
            fertileWindowEndDay: fertileWindowEndDay
        )
    }

    func makeEntry(text: String, date: Date = Date(), profile: CycleProfile) -> CycleLogEntry {
        let snapshot = snapshot(on: date, profile: profile)

        return CycleLogEntry(
            createdAt: date,
            text: text,
            cycleDay: snapshot.cycleDay,
            phase: snapshot.phase
        )
    }

    private func phase(
        cycleDay: Int,
        profile: CycleProfile,
        ovulationDay: Int
    ) -> CyclePhase {
        if cycleDay <= profile.periodLength {
            return .menstruation
        }

        if (ovulationDay - 1...ovulationDay + 1).contains(cycleDay) {
            return .ovulation
        }

        if cycleDay < ovulationDay {
            return .follicular
        }

        return .luteal
    }

    private func positiveModulo(_ value: Int, _ modulus: Int) -> Int {
        ((value % modulus) + modulus) % modulus
    }
}
