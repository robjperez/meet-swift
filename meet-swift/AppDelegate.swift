//
//  AppDelegate.swift
//  meet-swift
//
//  Created by rpc on 15/04/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static let kInitialBatteryKey = "initialBatteryLevel"


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics()])

        UIDevice.current.isBatteryMonitoringEnabled = true
        checkForUpdates()
        
        UserDefaults.standard.set(UIDevice.current.batteryLevel, forKey: AppDelegate.kInitialBatteryKey)
        
        //let _ = OTKLogger()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    fileprivate func checkForUpdates() {
        let sessionConf = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConf)
        
        session.dataTask(with: URL(string: "https://mobile-meet.tokbox.com/latest?product=meet-ios")!,
            completionHandler: { (data, reponse, error) -> Void in
                if let _ = error {
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                
                    if let updatedAppVersion = json["app_version"] as? String {
                        
                        var envs: NSDictionary?
                        var appVersion: String?
                        if let path = Bundle.main.path(forResource: "environment", ofType: "plist") {
                            envs = NSDictionary(contentsOfFile: path)
                        }
                        if let _ = envs {
                            appVersion = (envs?.object(forKey: "version") as! String)
                        }
                        
                        if let appVersionInt = Int(appVersion!), let updatedAppVersionInt = Int(updatedAppVersion) {
                            if  updatedAppVersionInt > appVersionInt {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    UIAlertView(title: "New version!",
                                        message: "There is a new version available, please update if from\n https://mobile-meet.tokbox.com",
                                        delegate: nil,
                                        cancelButtonTitle: "Ok").show()
                                    
                                })
                            }
                        }
                    }
                } catch {
                    NSLog("Error while searching for a new version")
                }
            }
        ).resume()
    }


}

