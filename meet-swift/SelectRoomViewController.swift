//
//  ViewController.swift
//  meet-swift
//
//  Created by rpc on 15/04/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import UIKit

class SelectRoomViewController: UIViewController {
    @IBOutlet weak var roomName: UITextField?
    @IBOutlet weak var userName: UITextField?
    @IBOutlet weak var joinButton: UIButton?
    
    var loadingAlert : UIAlertView?
    
    var roomInfo = RoomInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingAlert = UIAlertView(title: "Loading", message: "Getting session details", delegate: nil, cancelButtonTitle: nil);
        
        self.userName?.text = UIDevice.currentDevice().name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func joinClicked(sender: UIButton) {
        if roomName!.text.isEmpty {
            var alert = UIAlertView(title: "error",
                message: "You need to enter a room name",
                delegate: nil,
                cancelButtonTitle: "Ok")
            alert.show()
            return
        }
        
        self.view.endEditing(true)

        let urlString = "http://meet.tokbox.com/\(roomName!.text)"
        let urlRequest = NSURL(string: urlString)
        
        var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["content-type": "application/json"]
        
        var session = NSURLSession(configuration: configuration)
        
        self.roomInfo.roomName = roomName!.text
        self.roomInfo.userName = userName!.text
        
        let task = session.dataTaskWithURL(urlRequest!,
            completionHandler: {
                [weak self]
                (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                
                if error != nil {
                    UIAlertView(title: "Error", message: "Error while getting session details", delegate: nil, cancelButtonTitle: "Ok").show()
                    return
                }
                
                let json = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as! NSDictionary
                
                self!.roomInfo.apiKey = json["apiKey"] as? String
                self!.roomInfo.token = json["token"] as? String
                self!.roomInfo.sessionId = json["sessionId"] as? String
                
                self!.loadingAlert!.dismissWithClickedButtonIndex(0, animated: false)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self!.performSegueWithIdentifier("startChat", sender: self)
                }

            }
        )
        
        loadingAlert!.show()
        
        task.resume()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier! == "startChat" {
            var destination = segue.destinationViewController as! RoomViewController
            destination.roomInfo = self.roomInfo
        }
    }
}

