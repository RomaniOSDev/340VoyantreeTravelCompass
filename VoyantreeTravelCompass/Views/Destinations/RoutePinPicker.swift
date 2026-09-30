import CoreLocation
import MapKit
import SwiftUI

struct RoutePinPicker: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    var fallback: CLLocationCoordinate2D?
    @State private var region: MKCoordinateRegion
    @State private var query = ""
    @State private var searchError: String?

    init(latitude: Binding<Double>, longitude: Binding<Double>, fallback: CLLocationCoordinate2D? = nil) {
        _latitude = latitude
        _longitude = longitude
        self.fallback = fallback
        let start: CLLocationCoordinate2D
        if abs(latitude.wrappedValue) > 0.0001 || abs(longitude.wrappedValue) > 0.0001 {
            start = CLLocationCoordinate2D(latitude: latitude.wrappedValue, longitude: longitude.wrappedValue)
        } else {
            start = fallback ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        }
        _region = State(initialValue: MKCoordinateRegion(
            center: start,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Search a place", text: $query)
                    .textInputAutocapitalization(.words)
                Button("Find") { search() }
                    .frame(minHeight: 44)
            }
            if let searchError {
                Text(searchError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            ZStack {
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.primary)
                    .allowsHitTesting(false)
            }
            GoldActionButton(title: "Use map center", systemImage: "mappin.and.ellipse") {
                latitude = region.center.latitude
                longitude = region.center.longitude
            }
            Text(String(format: "%.5f, %.5f", latitude, longitude))
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
        }
    }

    private func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = region
        MKLocalSearch(request: request).start { response, error in
            if let item = response?.mapItems.first {
                region.center = item.placemark.coordinate
                latitude = item.placemark.coordinate.latitude
                longitude = item.placemark.coordinate.longitude
                searchError = nil
            } else {
                searchError = error?.localizedDescription ?? "No map match."
            }
        }
    }
}

enum RouteMapRegion {
    static func fitting(_ stops: [RouteStop], fallback: CLLocationCoordinate2D? = nil) -> MKCoordinateRegion {
        let pinned = stops.filter(\.isPinned)
        if pinned.isEmpty {
            let center = fallback ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
            return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        }
        let lats = pinned.map(\.latitude)
        let lons = pinned.map(\.longitude)
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.7, 0.012),
                longitudeDelta: max((maxLon - minLon) * 1.7, 0.012)
            )
        )
    }
}
