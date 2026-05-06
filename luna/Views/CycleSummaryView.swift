import SwiftUI

struct CycleSummaryView: View {
    var snapshot: CycleSnapshot
    @Binding var profile: CycleProfile
    var notificationsEnabled: Bool
    var notificationStatus: String?
    var enableNotifications: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                phaseBlock
                metricRows
                cycleControls
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .background(snapshot.phase.tint.opacity(0.12))
    }

    private var header: some View {
        HStack {
            Text("Luna")
                .font(.system(.title3, design: .rounded, weight: .semibold))

            Spacer()

            if let notificationStatus {
                Text(notificationStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: enableNotifications) {
                Image(systemName: notificationsEnabled ? "bell.fill" : "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Cycle reminders")
        }
    }

    private var phaseBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.phase.displayName)
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            HStack(spacing: 10) {
                Text("Day \(snapshot.cycleDay)")
                    .font(.system(.title2, design: .rounded, weight: .medium))

                Text(snapshot.phase.shortSignal.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(snapshot.phase.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(snapshot.phase.tint.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        }
    }

    private var metricRows: some View {
        VStack(spacing: 10) {
            MetricRow(
                title: "Next period",
                value: nextPeriodText,
                symbol: "calendar"
            )

            MetricRow(
                title: "Fertile window",
                value: "Days \(snapshot.fertileWindowStartDay)-\(snapshot.fertileWindowEndDay)",
                symbol: "sparkle.magnifyingglass"
            )
        }
    }

    private var cycleControls: some View {
        VStack(spacing: 10) {
            DatePicker(
                "Last period",
                selection: $profile.lastPeriodStart,
                displayedComponents: .date
            )

            Stepper(
                "Cycle \(profile.cycleLength)d",
                value: $profile.cycleLength,
                in: 21...45
            )

            Stepper(
                "Period \(profile.periodLength)d",
                value: $profile.periodLength,
                in: 2...10
            )
        }
        .font(.subheadline)
        .padding(.top, 4)
    }

    private var nextPeriodText: String {
        if snapshot.daysUntilNextPeriod == 0 {
            return "Today"
        }

        if snapshot.daysUntilNextPeriod == 1 {
            return "Tomorrow"
        }

        return "\(snapshot.daysUntilNextPeriod)d"
    }
}

private struct MetricRow: View {
    var title: String
    var value: String
    var symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

private extension CyclePhase {
    var tint: Color {
        switch self {
        case .menstruation:
            return Color(red: 0.72, green: 0.18, blue: 0.26)
        case .follicular:
            return Color(red: 0.05, green: 0.45, blue: 0.40)
        case .ovulation:
            return Color(red: 0.18, green: 0.35, blue: 0.73)
        case .luteal:
            return Color(red: 0.62, green: 0.33, blue: 0.12)
        }
    }
}
