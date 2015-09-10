//
//  ViewController.swift
//  meet-swift
//
//  Created by rpc on 15/04/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import UIKit
import OpenTok

class SelectRoomViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var roomName: UITextField?
    @IBOutlet weak var userName: UITextField?
    @IBOutlet weak var joinButton: UIButton?
    @IBOutlet weak var simulcastLevel: UITextField?
    @IBOutlet weak var simulcastPickerView: UIPickerView?
    @IBOutlet weak var subscriberSimulcast: UISwitch?
    
    var loadingAlert: UIAlertView?
    
    var simulcastLevels = [OTPublisherKitSimulcastLevel.LevelNone,
        OTPublisherKitSimulcastLevel.LevelVGA,
        OTPublisherKitSimulcastLevel.Level720p]
    
    var selectedSimulcastLevel: OTPublisherKitSimulcastLevel = OTPublisherKitSimulcastLevel.LevelNone
    
    var roomInfo = RoomInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingAlert = UIAlertView(title: "Loading", message: "Getting session details", delegate: nil, cancelButtonTitle: nil);
        
        self.userName?.text = UIDevice.currentDevice().name
        
        self.simulcastLevel?.text = simulcastLevelToString(selectedSimulcastLevel)
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
            destination.simulcastLevel = self.selectedSimulcastLevel
            destination.subscriberSimulcastEnabled = self.subscriberSimulcast!.on
        }
    }
    
    // MARK: picker view code
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == self.simulcastLevel {
            simulcastPickerView?.hidden = false
            self.roomName?.resignFirstResponder()
            self.userName?.resignFirstResponder()
            return false
        } else {
            simulcastPickerView?.hidden = true
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return simulcastLevels.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return simulcastLevelToString(simulcastLevels[row])
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        simulcastLevel!.text = simulcastLevelToString(simulcastLevels[row])
        selectedSimulcastLevel = simulcastLevels[row]
        
        simulcastPickerView?.hidden = true
    }
    
    func simulcastLevelToString(level: OTPublisherKitSimulcastLevel) -> String
    {
        switch level {
        case OTPublisherKitSimulcastLevel.LevelNone: return "None"
        case OTPublisherKitSimulcastLevel.LevelVGA: return "VGA"
        case OTPublisherKitSimulcastLevel.Level720p: return "720p"
        default: return ""
        }
    }
}

