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
    case whenInUse
    case always
}

class AsyncCurrentLocation: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    var callback: ((CLLocation?) -> Void)?
    
    let requestOnce: Bool
    
    required init(accuracy: CLLocationAccuracy, requestOnce: Bool = true, authorization: LocationAuthorization, callback: @escaping (CLLocation?) -> Void) {
        self.callback = callback
        self.requestOnce = requestOnce
        super.init()
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager.desiredAccuracy = accuracy
            locationManager.delegate = self
            objc_setAssociatedObject(locationManager as Any, &containerKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                requestLocation()
            case .notDetermined:
                switch authorization {
                case .whenInUse:
                    locationManager.requestWhenInUseAuthorization()
                case .always:
                    locationManager.requestAlwaysAuthorization()
                }
            default:
                returnLocation(nil)
            }
        }
    }
    
    func returnLocation(_ location: CLLocation?) {
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        returnLocation(locations.last)
        if #available(iOS 9.0, *) {
            if requestOnce {
                return
            }
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .denied:
            returnLocation(nil)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
    case location(CLLocation)
    case current(accuracy: CLLocationAccuracy, authorization: LocationAuthorization)
    
    public func getLocation(_ closure: @escaping (CLLocation?) -> ()) {
        switch self {
        case .location(let location):
            closure(location)
        case .current(let accuracy, let authorization):
            //TODO: it seems like an iOS9 bug that when using requestOnce = true, it takes much longer time to response.
            let _ = AsyncCurrentLocation(accuracy: accuracy, requestOnce: false, authorization: authorization, callback: closure)
        }
    }
}
