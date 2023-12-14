//
//  LocationManager.swift
//  DiaBLE
//
//  Created by Marian Dugaesescu on 07/12/2023.
//

import Combine
import Foundation
import MapKit

func start() {
    print("start location manager")

    // start background mode
    //BackgroundManager.shared.enabled = true

    
}

func stop() {
    print("stop location manager")

    // stop background mode
    BackgroundManager.shared.enabled = false

    
}

func restart() {
    print("restart location manager")

    stop()
    start()
}



// MARK: - BackgroundManager

public class BackgroundManager: NSObject {
    // MARK: Lifecycle
    
    override init() {}

    // MARK: Internal

    static let shared = BackgroundManager()

    var isShowLog: Bool = true
    let systemVersion: Float = (UIDevice.current.systemVersion as NSString).floatValue

    var enabled: Bool = false {
        didSet {
            guard enabled != oldValue else {
                return
            }

            if enabled {
                
              
                
                guard isValidConfig else {
                    enabled = false
                    return
                }

                locationManager = makeLocationManager()

                addAppLifeCircleNotification()
            } else {
                
                
                locationManager?.stopUpdatingLocation()
                locationManager = nil

                removeAppLifeCircleNotification()
            }
        }
    }

    // MARK: Private

    private var locationManager: CLLocationManager?
   
    
    
  
    
    
    
    private var isValidConfig: Bool {
        if let info = Bundle.main.infoDictionary,
           info.keys.contains("NSLocationAlwaysAndWhenInUseUsageDescription"),
           info.keys.contains("NSLocationWhenInUseUsageDescription"),
           let bgModels = info["UIBackgroundModes"] as? [String],
           bgModels.contains("fetch"),
           bgModels.contains("location")
        {
            return true
        }

        return false
    }

    private var isAuthBackground: Bool {
        guard enabled else {
            return false
        }

        let status = locationManager?.authorizationStatus

        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}


private extension BackgroundManager {
    func start() {
        guard isAuthBackground else {
            return
        }

        locationManager?.startUpdatingLocation()
    }

    func stop() {
        guard isAuthBackground else {
            return
        }

        locationManager?.stopUpdatingLocation()
    }

    func makeLocationManager() -> CLLocationManager {
        let manager = CLLocationManager()
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.pausesLocationUpdatesAutomatically = false
        manager.requestAlwaysAuthorization()
        manager.requestWhenInUseAuthorization()

        return manager
    }

    func addAppLifeCircleNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willTerminateNotification),
                                               name: UIApplication.willTerminateNotification,
                                               object: UIApplication.shared)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: UIApplication.shared)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForegroundNotification),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: UIApplication.shared)
    }

    func removeAppLifeCircleNotification() {
        NotificationCenter.default.removeObserver(self)
    }
}



// MARK: CLLocationManagerDelegate

extension BackgroundManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
        default:
            break
        }
    }
}
//

// MARK: - App LifeCircle

extension BackgroundManager {
    @objc func willTerminateNotification() {
        guard isAuthBackground else {
            return
        }

        UIApplication.shared.beginReceivingRemoteControlEvents()
        start()
    }

    @objc func applicationDidEnterBackground() {
        guard isAuthBackground else {
            return
        }

        var bgTask: UIBackgroundTaskIdentifier?
        bgTask = UIApplication.shared.beginBackgroundTask {
            DispatchQueue.main.async {
                if let task = bgTask, task != .invalid {
                    bgTask = .invalid
                }
            }
        }

        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                if let task = bgTask, task != .invalid {
                    bgTask = .invalid
                }
            }
        }

        start()
    }

    @objc func willEnterForegroundNotification() {
        guard isAuthBackground else {
            return
        }

        stop()
    }
   
}



