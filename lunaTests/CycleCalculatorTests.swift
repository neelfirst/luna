import XCTest
@testable import luna

final class CycleCalculatorTests: XCTestCase {
    func testCycleDayWrapsToNextCycle() {
        let calendar = utcCalendar()
        let calculator = CycleCalculator(calendar: calendar)
        let profile = CycleProfile(
            lastPeriodStart: date(2026, 5, 1, calendar: calendar),
            cycleLength: 28,
            periodLength: 5
        )

        let snapshot = calculator.snapshot(
            on: date(2026, 5, 29, calendar: calendar),
            profile: profile
        )

        XCTAssertEqual(snapshot.cycleDay, 1)
        XCTAssertEqual(snapshot.phase, .menstruation)
        XCTAssertEqual(snapshot.daysUntilNextPeriod, 28)
    }

    func testPhaseProgression() {
        let calendar = utcCalendar()
        let calculator = CycleCalculator(calendar: calendar)
        let profile = CycleProfile(
            lastPeriodStart: date(2026, 5, 1, calendar: calendar),
            cycleLength: 28,
            periodLength: 5
        )

        XCTAssertEqual(
            calculator.snapshot(
                on: date(2026, 5, 3, calendar: calendar),
                profile: profile
            ).phase,
            .menstruation
        )
        XCTAssertEqual(
            calculator.snapshot(
                on: date(2026, 5, 14, calendar: calendar),
                profile: profile
            ).phase,
            .ovulation
        )
        XCTAssertEqual(
            calculator.snapshot(
                on: date(2026, 5, 24, calendar: calendar),
                profile: profile
            ).phase,
            .luteal
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day
            )
        )!
    }
}
