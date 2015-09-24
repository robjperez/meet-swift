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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics()])

        UIDevice.currentDevice().batteryMonitoringEnabled = true
        checkForUpdates()
        
        NSUserDefaults.standardUserDefaults().setObject(UIDevice.currentDevice().batteryLevel, forKey: AppDelegate.kInitialBatteryKey)
        
        //let a = OTKLogger()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }
    
    private func checkForUpdates() {
        let sessionConf = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConf)
        
        session.dataTaskWithURL(NSURL(string: "https://mobile-meet.tokbox.com/latest?product=meet-ios")!,
            completionHandler: { (data, reponse, error) -> Void in
                if let _ = error {
                    return
                }
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
                
                    if let updatedAppVersion = json["app_version"] as? String {
                        
                        var envs: NSDictionary?
                        var appVersion: String?
                        if let path = NSBundle.mainBundle().pathForResource("environment", ofType: "plist") {
                            envs = NSDictionary(contentsOfFile: path)
                        }
                        if let _ = envs {
                            appVersion = (envs?.objectForKey("version") as! String)
                        }
                        
                        if let appVersionInt = Int(appVersion!), updatedAppVersionInt = Int(updatedAppVersion) {
                            if  updatedAppVersionInt > appVersionInt {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
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

