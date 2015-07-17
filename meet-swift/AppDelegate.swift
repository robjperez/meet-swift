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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics()])

        checkForUpdates()
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
                if error == nil {
                    let json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as! NSDictionary
                
                    if let updatedAppVersion = json["app_version"] as? String {
                        
                        var envs: NSDictionary?
                        var appVersion: String?
                        if let path = NSBundle.mainBundle().pathForResource("environment", ofType: "plist") {
                            envs = NSDictionary(contentsOfFile: path)
                        }
                        if let dict = envs {
                            appVersion = (envs?.objectForKey("version") as! String)
                        }
                        
                        if let appVersionInt = appVersion!.toInt(), updatedAppVersionInt = updatedAppVersion.toInt() {
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
                }
            }
        ).resume()
    }


}

