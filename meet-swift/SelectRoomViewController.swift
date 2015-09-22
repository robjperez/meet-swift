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
    
    var simulcastLevelsCustomValues = [
        OTPublisherKitSimulcastLevel.LevelVGA,
        OTPublisherKitSimulcastLevel.Level720p
    ]
    
    var selectedSimulcastLevel: OTPublisherKitSimulcastLevel = OTPublisherKitSimulcastLevel.LevelNone
    var selectedSimulcastCustomValues : Bool = false
    
    var roomInfo = RoomInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingAlert = UIAlertView(title: "Loading", message: "Getting session details", delegate: nil, cancelButtonTitle: nil);
        
        self.userName?.text = UIDevice.currentDevice().name
        
        self.simulcastLevel?.text = simulcastLevelToString(OTPublisherKitSimulcastLevel.LevelNone)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func joinClicked(sender: UIButton) {
        guard let _ = roomName!.text else {
            let alert = UIAlertView(title: "error",
                message: "You need to enter a room name",
                delegate: nil,
                cancelButtonTitle: "Ok")
            alert.show()
            return
        }
        
        self.view.endEditing(true)

        let urlString = "http://meet.tokbox.com/\(roomName!.text)"
        let urlRequest = NSURL(string: urlString)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = ["content-type": "application/json"]
        
        let session = NSURLSession(configuration: configuration)
        
        self.roomInfo.roomName = roomName!.text
        self.roomInfo.userName = userName!.text
        
        let task = session.dataTaskWithURL(urlRequest!,
            completionHandler: {
                [weak self]
                (data, response, error) -> Void in
                
                if let _ = error {
                    UIAlertView(title: "Error", message: "Error while getting session details", delegate: nil, cancelButtonTitle: "Ok").show()
                    return
                }
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
                    
                    self!.roomInfo.apiKey = json["apiKey"] as? String
                    self!.roomInfo.token = json["token"] as? String
                    self!.roomInfo.sessionId = json["sessionId"] as? String
                    
                    self!.loadingAlert!.dismissWithClickedButtonIndex(0, animated: false)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self!.performSegueWithIdentifier("startChat", sender: self)
                    }
                } catch {
                    UIAlertView(title: "Error", message: "Error while getting session details", delegate: nil, cancelButtonTitle: "Ok").show()
                    return
                }

            }
        )
        
        loadingAlert!.show()
        
        task.resume()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier! == "startChat" {
            let destination = segue.destinationViewController as! RoomViewController
            destination.roomInfo = self.roomInfo
            destination.simulcastLevel = self.selectedSimulcastLevel
            destination.subscriberSimulcastEnabled = self.subscriberSimulcast!.on
            destination.simulcastUseCustomValues = self.selectedSimulcastCustomValues
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
        return simulcastLevels.count + simulcastLevelsCustomValues.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        var calculatedRow = row
        if row >= simulcastLevels.count {
            calculatedRow = row - simulcastLevels.count + 1
        }
        
        return simulcastLevelToString(simulcastLevels[calculatedRow],
            customValues: isUsingSimulcastCustomValues(row))
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        var calculatedRow = row
        if row >= simulcastLevels.count {
            calculatedRow = row - simulcastLevels.count + 1
        }
        
        simulcastLevel!.text = simulcastLevelToString(simulcastLevels[calculatedRow],
            customValues: isUsingSimulcastCustomValues(row))
        selectedSimulcastLevel = simulcastLevels[calculatedRow]
        selectedSimulcastCustomValues = isUsingSimulcastCustomValues(row)
        
        simulcastPickerView?.hidden = true
    }
    
    func simulcastLevelToString(level: OTPublisherKitSimulcastLevel, customValues: Bool = false) -> String
    {
        var retValue = ""
        switch level {
        case OTPublisherKitSimulcastLevel.LevelNone: retValue = "None"
        case OTPublisherKitSimulcastLevel.LevelVGA: retValue = "VGA"
        case OTPublisherKitSimulcastLevel.Level720p: retValue = "720p"
        default: retValue = "None"
        }
        
        if customValues {
            return retValue + " (CUSTOM)"
        } else {
            return retValue
        }
    }
    
    func isUsingSimulcastCustomValues(index: Int) -> Bool {
        return index > (simulcastLevels.count - 1)
    }
}

