//
//  PostalCode.swift
//  Interactive Labs
//
//  Created by Rex Sheng on 2/15/16.
//  Copyright © 2016 Interactive Labs. All rights reserved.
//

import CoreLocation

private var containerKey: Void?

public enum LocationAuthorization {
    case WhenInUse
    case Always
}

class AsyncCurrentLocation: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    var callback: ((CLLocation?) -> Void)?

    let requestOnce: Bool

    required init(accuracy: CLLocationAccuracy, requestOnce: Bool = true, authorization: LocationAuthorization, callback: (CLLocation?) -> Void) {
        self.callback = callback
        self.requestOnce = requestOnce
        super.init()
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager.desiredAccuracy = accuracy
            locationManager.delegate = self
            objc_setAssociatedObject(locationManager, &containerKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                requestLocation()
            case .NotDetermined:
                switch authorization {
                case .WhenInUse:
                    locationManager.requestWhenInUseAuthorization()
                case .Always:
                    locationManager.requestAlwaysAuthorization()
                }
            default:
                returnLocation(nil)
            }
        }
    }

    func returnLocation(location: CLLocation?) {
        print("return location \(location)")
        callback?(location)
        callback = nil
        locationManager = nil
    }

    func requestLocation() {
        if #available(iOS 9.0, *) {
            if requestOnce {
                locationManager.requestLocation()
                return
            }
        }
        locationManager.startUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        returnLocation(locations.last)
        if #available(iOS 9.0, *) {
            if requestOnce {
                return
            }
        }
        manager.stopUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            requestLocation()
        case .Denied:
            returnLocation(nil)
        default:
            break
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        returnLocation(manager.location)
        print("location failed with error \(error.localizedDescription)")
        if #available(iOS 9.0, *) {
            if requestOnce {
                return
            }
        }
        manager.stopUpdatingLocation()
    }

    deinit {
        print("deinit AsyncCurrentLocation")
    }
}

public enum Geocode {
    case Location(CLLocation)
    case Current(accuracy: CLLocationAccuracy, authorization: LocationAuthorization)

    public func getLocation(closure: (CLLocation?) -> ()) {
        switch self {
        case .Location(let location):
            closure(location)
        case .Current(let accuracy, let authorization):
            //TODO: it seems like an iOS9 bug that when using requestOnce = true, it takes much longer time to response.
            let _ = AsyncCurrentLocation(accuracy: accuracy, requestOnce: false, authorization: authorization, callback: closure)
        }
    }
}
