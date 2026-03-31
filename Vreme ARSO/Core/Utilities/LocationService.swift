import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?

    private let manager = CLLocationManager()
    private var pendingLocationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var pendingLocationTimeoutTask: Task<Void, Never>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAccessIfNeeded() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func refreshLocation() {
        guard isAuthorizedForLocation else {
            clearCurrentLocation()
            resolvePendingLocationRequest(with: nil)
            return
        }

        manager.requestLocation()
    }

    func refreshLocationAndWait(timeoutNanoseconds: UInt64 = 4_000_000_000) async -> CLLocation? {
        guard isAuthorizedForLocation else {
            clearCurrentLocation()
            return nil
        }

        pendingLocationTimeoutTask?.cancel()
        if let pendingLocationContinuation {
            self.pendingLocationContinuation = nil
            pendingLocationContinuation.resume(returning: nil)
        }

        return await withCheckedContinuation { continuation in
            pendingLocationContinuation = continuation
            manager.requestLocation()

            pendingLocationTimeoutTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)

                guard self.pendingLocationContinuation != nil else { return }
                self.resolvePendingLocationRequest(with: nil)
            }
        }
    }

    private var isAuthorizedForLocation: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    private func clearCurrentLocation() {
        currentLocation = nil
        WidgetSharedStore.syncCurrentLocation(nil)
    }

    private func resolvePendingLocationRequest(with location: CLLocation?) {
        pendingLocationTimeoutTask?.cancel()
        pendingLocationTimeoutTask = nil

        guard let pendingLocationContinuation else { return }
        self.pendingLocationContinuation = nil
        pendingLocationContinuation.resume(returning: location)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if isAuthorizedForLocation {
            manager.requestLocation()
        } else {
            clearCurrentLocation()
            resolvePendingLocationRequest(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        WidgetSharedStore.syncCurrentLocation(currentLocation)
        resolvePendingLocationRequest(with: currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Napaka lokacije: %@", String(describing: error))
        resolvePendingLocationRequest(with: nil)
    }
}
