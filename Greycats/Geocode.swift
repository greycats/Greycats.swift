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

    init(accuracy: CLLocationAccuracy, authorization: LocationAuthorization, callback: (CLLocation?) -> Void) {
        super.init()
        self.callback = callback
        if locationManager == nil {
            locationManager = CLLocationManager()
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
            locationManager.requestLocation()
        } else {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        returnLocation(locations.last)
        if #available(iOS 9.0, *) {
        } else {
            manager.stopUpdatingLocation()
        }
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
        } else {
            manager.stopUpdatingLocation()
        }
    }

    deinit {
        print("deinit AsyncCurrentLocation")
    }
}

public enum Geocode {
    case Location(CLLocation)
    case Current(CLLocationAccuracy, LocationAuthorization)

    public func getLocation(closure: (CLLocation?) -> ()) {
        switch self {
        case .Location(let location):
            closure(location)
        case .Current(let accuracy, let authorization):
            let _ = AsyncCurrentLocation(accuracy: accuracy, authorization: authorization, callback: closure)
        }
    }
}
