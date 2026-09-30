import CoreLocation
import Foundation

enum GeoMath {
    static let arrivalThreshold: CLLocationDistance = 75
    static let walkingMetersPerMinute: CLLocationDistance = 83

    static func coordinate(lat: Double, lon: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    static func walkingMinutes(meters: CLLocationDistance) -> Int {
        max(1, Int((meters / walkingMetersPerMinute).rounded()))
    }

    static func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    static func formatWalking(_ meters: CLLocationDistance) -> String {
        let minutes = walkingMinutes(meters: meters)
        if minutes < 60 {
            return "\(minutes) min walk"
        }
        let hours = minutes / 60
        let remain = minutes % 60
        return remain == 0 ? "\(hours) h walk" : "\(hours) h \(remain) min walk"
    }
}

extension RouteStop {
    var coordinate: CLLocationCoordinate2D {
        GeoMath.coordinate(lat: latitude, lon: longitude)
    }
}
