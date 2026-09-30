import Charts
import SwiftUI

private struct NamedCount: Identifiable {
    var id: String { name }
    let name: String
    let value: Int
}

private struct MonthCount: Identifiable {
    var id: Date { month }
    let month: Date
    let value: Int
}

private struct TaskCategoryStat: Identifiable {
    var id: String { category + status }
    let category: String
    let status: String
    let value: Int
}

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var showsDoneButton = false

    private var visitedCount: Int { store.destinations.filter(\.visited).count }
    private var upcomingCount: Int { store.destinations.filter { !$0.visited }.count }
    private var completedTasks: Int { store.tripTasks.filter(\.completed).count }
    private var openTasks: Int { store.tripTasks.filter { !$0.completed }.count }
    private var tripDays: Int { store.destinations.reduce(0) { $0 + $1.durationDays } }

    private var visitRows: [NamedCount] {
        [
            NamedCount(name: "Visited", value: visitedCount),
            NamedCount(name: "Upcoming", value: upcomingCount)
        ]
    }

    private var phraseRows: [NamedCount] {
        store.destinations.map { destination in
            NamedCount(
                name: destination.name,
                value: store.phrases.filter { $0.destinationId == destination.id }.count
            )
        }
    }

    private var taskCategoryRows: [TaskCategoryStat] {
        TaskCategory.allCases.flatMap { category in
            let items = store.tripTasks.filter { $0.category == category.rawValue }
            return [
                TaskCategoryStat(category: category.rawValue, status: "Open", value: items.filter { !$0.completed }.count),
                TaskCategoryStat(category: category.rawValue, status: "Done", value: items.filter(\.completed).count)
            ]
        }
    }

    private var monthlyRows: [MonthCount] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.destinations) { destination -> Date in
            let components = calendar.dateComponents([.year, .month], from: destination.date)
            return calendar.date(from: components) ?? destination.date
        }
        return grouped
            .map { MonthCount(month: $0.key, value: $0.value.count) }
            .sorted { $0.month < $1.month }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryGrid

                if store.destinations.isEmpty && store.tripTasks.isEmpty && store.phrases.isEmpty {
                    emptyState
                } else {
                    visitChart
                    monthChart
                    taskChart
                    phraseChart
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgPass")
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryTile(title: "Places", value: store.destinations.count, icon: "airplane")
            summaryTile(title: "Visited", value: visitedCount, icon: "checkmark.seal.fill")
            summaryTile(title: "Trip days", value: tripDays, icon: "calendar")
            summaryTile(title: "Tasks", value: store.tripTasks.count, icon: "checklist")
            summaryTile(title: "Phrases", value: store.phrases.count, icon: "text.bubble")
            summaryTile(title: "Stops", value: store.itineraryDays.count, icon: "mappin.and.ellipse")
        }
    }

    private func summaryTile(title: String, value: Int, icon: String) -> some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primary)
                Text("\(value)")
                    .font(AppTheme.displayTitle.monospacedDigit())
                Text(title.uppercased())
                    .font(AppTheme.trackedLabel)
                    .tracking(0.8)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyState: some View {
        TicketCard {
            VStack(spacing: 10) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.primary)
                Text("No stats yet")
                    .font(.headline)
                Text("Add a trip with walking stops to see visit, packing, and phrase charts.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var visitChart: some View {
        chartCard(title: "Places by status") {
            Chart(visitRows) { row in
                BarMark(
                    x: .value("Status", row.name),
                    y: .value("Count", row.value)
                )
                .foregroundStyle(AppTheme.goldLift)
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
    }

    private var monthChart: some View {
        chartCard(title: "Planned trips by month") {
            if monthlyRows.isEmpty {
                chartPlaceholder("Dates will appear after you add places.")
            } else {
                Chart(monthlyRows) { row in
                    AreaMark(
                        x: .value("Month", row.month),
                        y: .value("Trips", row.value)
                    )
                    .foregroundStyle(AppTheme.primary.opacity(0.22))
                    LineMark(
                        x: .value("Month", row.month),
                        y: .value("Trips", row.value)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Month", row.month),
                        y: .value("Trips", row.value)
                    )
                    .foregroundStyle(AppTheme.accent)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private var taskChart: some View {
        chartCard(title: "Packing tasks") {
            if store.tripTasks.isEmpty {
                chartPlaceholder("Prepare a trip to track packing progress.")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(completedTasks) done · \(openTasks) open")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Chart(taskCategoryRows) { row in
                        BarMark(
                            x: .value("Count", row.value),
                            y: .value("Category", row.category)
                        )
                        .foregroundStyle(by: .value("Status", row.status))
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        "Open": AppTheme.primary,
                        "Done": AppTheme.accent
                    ])
                    .frame(height: 180)
                }
            }
        }
    }

    private var phraseChart: some View {
        chartCard(title: "Phrases per place") {
            if phraseRows.allSatisfy({ $0.value == 0 }) {
                chartPlaceholder("Save phrases to compare them by destination.")
            } else {
                Chart(phraseRows) { row in
                    BarMark(
                        x: .value("Phrases", row.value),
                        y: .value("Place", row.name)
                    )
                    .foregroundStyle(AppTheme.goldLift)
                    .cornerRadius(4)
                }
                .frame(height: max(160, CGFloat(phraseRows.count) * 36))
            }
        }
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        TicketCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title.uppercased())
                    .font(AppTheme.trackedLabel)
                    .tracking(1.1)
                content()
            }
        }
    }

    private func chartPlaceholder(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}
