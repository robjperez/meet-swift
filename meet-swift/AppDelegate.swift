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
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

