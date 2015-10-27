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
    @IBOutlet weak var capturerResolution: UITextField?
    @IBOutlet weak var capturerResolutionPickerView: UIPickerView?
    @IBOutlet weak var subscriberSimulcast: UISwitch?
    
    var loadingAlert: UIAlertView?
    
    var capturerResolutions : [OTCameraCaptureResolution] = [
            OTCameraCaptureResolution.Low,
            OTCameraCaptureResolution.Medium,
            OTCameraCaptureResolution.High]
    
    var selectedCapturerResolution: OTCameraCaptureResolution =
        OTCameraCaptureResolution.Medium
    
    var roomInfo = RoomInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingAlert = UIAlertView(title: "Loading", message: "Getting session details", delegate: nil, cancelButtonTitle: nil);
        
        self.userName?.text = UIDevice.currentDevice().name
        
        self.capturerResolution?.text = capturerResolutionToString(OTCameraCaptureResolution.Medium)
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

        let urlString = "https://meet.tokbox.com/\(roomName!.text!)"
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
            destination.selectedCapturerResolution = self.selectedCapturerResolution
            destination.subscriberSimulcastEnabled = self.subscriberSimulcast!.on
        }
    }
    
    // MARK: picker view code
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == self.capturerResolution {
            capturerResolutionPickerView?.hidden = false
            self.roomName?.resignFirstResponder()
            self.userName?.resignFirstResponder()
            return false
        } else {
            capturerResolutionPickerView?.hidden = true
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
        return capturerResolutions.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return capturerResolutionToString(capturerResolutions[row])
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        capturerResolution!.text = capturerResolutionToString(capturerResolutions[row])
        selectedCapturerResolution = capturerResolutions[row]
        
        capturerResolutionPickerView?.hidden = true
    }
    
    func capturerResolutionToString(level: OTCameraCaptureResolution) -> String
    {
        switch level {
        case OTCameraCaptureResolution.Low: return "Low (QVGA)"
        case OTCameraCaptureResolution.Medium: return "Medium (VGA)"
        case OTCameraCaptureResolution.High: return "High (HD)"
        }
    }
}

