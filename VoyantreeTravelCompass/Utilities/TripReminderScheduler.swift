import Foundation
import UserNotifications

enum TripReminderScheduler {
    private static let offsets = [7, 3, 1]

    static func refresh(for destination: Destination) {
        if destination.visited {
            cancel(for: destination.id)
            return
        }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted { schedule(for: destination) }
                }
            case .authorized, .provisional:
                schedule(for: destination)
            default:
                break
            }
        }
    }

    static func cancel(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers(for: id))
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func schedule(for destination: Destination) {
        cancel(for: destination.id)
        let calendar = Calendar.current
        for days in offsets {
            guard let raw = calendar.date(byAdding: .day, value: -days, to: destination.date) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: raw)
            components.hour = 9
            components.minute = 0
            guard let fireDate = calendar.date(from: components), fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = destination.name
            switch days {
            case 1:
                content.body = "Tomorrow in \(destination.country). Check packing, documents, and phrases."
            case 3:
                content.body = "3 days until \(destination.name). Finish packing tasks."
            default:
                content.body = "7 days until \(destination.name). Review documents and key phrases."
            }
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: identifier(for: destination.id, days: days),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    private static func identifier(for id: UUID, days: Int) -> String {
        "trip-\(id.uuidString)-\(days)"
    }

    private static func identifiers(for id: UUID) -> [String] {
        offsets.map { identifier(for: id, days: $0) }
    }
}
