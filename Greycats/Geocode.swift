//
//  PostalCode.swift
//  Interactive Labs
//
//  Created by Rex Sheng on 2/15/16.
//  Copyright © 2016 Interactive Labs. All rights reserved.
//

import CoreLocation

public enum Geocode {
	class GeocodeContainer: NSObject, CLLocationManagerDelegate {
		var locationManager: CLLocationManager!

		var callback: (CLLocation? -> Void)?

		func current(accuracy: CLLocationAccuracy, callback: CLLocation? -> Void) {
			locationManager?.stopUpdatingLocation()
			self.callback = callback
			if locationManager == nil {
				locationManager = CLLocationManager()
				locationManager.delegate = self
				locationManager.desiredAccuracy = accuracy
				if #available(iOS 9.0, *) {
					locationManager.requestLocation()
				} else {
					locationManager.requestWhenInUseAuthorization()
					locationManager.startUpdatingLocation()
				}
			}
		}

		func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
			callback?(locations.last)
			callback = nil
			if #available(iOS 9.0, *) {
			} else {
				manager.stopUpdatingLocation()
			}
		}

		func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
			callback?(manager.location)
			callback = nil
			print(error.localizedDescription)
			if #available(iOS 9.0, *) {
			} else {
				manager.stopUpdatingLocation()
			}
		}

		deinit {
			print("deinit GeocodeContainer")
		}
	}

	private static var geoContainer = GeocodeContainer()
	case Location(CLLocation)
	case Current(CLLocationAccuracy)

	public func getLocation(closure: (CLLocation?) -> ()) {
		switch self {
		case .Location(let location):
			closure(location)
		case .Current(let accuracy):
			switch CLLocationManager.authorizationStatus() {
			case .AuthorizedAlways, .AuthorizedWhenInUse:
				Geocode.geoContainer.current(accuracy, callback: closure)
			default:
				closure(nil)
			}
		}
	}

	public func zipcode(closure: (String?) -> ()) {
		getLocation { location in
			guard let location = location else { return closure(nil) }
			CLGeocoder().reverseGeocodeLocation(location) { (addresses, error) in
				if let addresses = addresses {
					for address in addresses where address.ISOcountryCode == "US" {
						if let postalCode = address.postalCode {
							closure(postalCode)
							return
						}
					}
				}
				closure(nil)
			}
		}
	}
}