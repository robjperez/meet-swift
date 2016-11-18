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
            OTCameraCaptureResolution.low,
            OTCameraCaptureResolution.medium,
            OTCameraCaptureResolution.high]
    
    var selectedCapturerResolution: OTCameraCaptureResolution =
        OTCameraCaptureResolution.medium
    
    var roomInfo = RoomInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingAlert = UIAlertView(title: "Loading", message: "Getting session details", delegate: nil, cancelButtonTitle: nil)
        
        self.userName?.text = UIDevice.current.name
        
        self.capturerResolution?.text = capturerResolutionToString(OTCameraCaptureResolution.medium)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func joinClicked(_ sender: UIButton) {
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
        let urlRequest = URL(string: urlString)
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["content-type": "application/json"]
        
        let session = URLSession(configuration: configuration)
        
        self.roomInfo.roomName = roomName!.text
        self.roomInfo.userName = userName!.text
        
        let task = session.dataTask(with: urlRequest!,
            completionHandler: {
                [weak self]
                (data, response, error) -> Void in
                
                if let _ = error {
                    UIAlertView(title: "Error", message: "Error while getting session details", delegate: nil, cancelButtonTitle: "Ok").show()
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                    
                    self!.roomInfo.apiKey = json["apiKey"] as? String
                    self!.roomInfo.token = json["token"] as? String
                    self!.roomInfo.sessionId = json["sessionId"] as? String
                                                            
                    self!.loadingAlert!.dismiss(withClickedButtonIndex: 0, animated: false)
                    
                    DispatchQueue.main.async {
                        self!.performSegue(withIdentifier: "startChat", sender: self)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "startChat" {
            let destination = segue.destination as! RoomViewController
            destination.roomInfo = self.roomInfo
            //destination.selectedCapturerResolution = self.selectedCapturerResolution
            destination.subscriberSimulcastEnabled = self.subscriberSimulcast!.isOn
        }
    }
    
    // MARK: picker view code
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == self.capturerResolution {
            capturerResolutionPickerView?.isHidden = false
            self.roomName?.resignFirstResponder()
            self.userName?.resignFirstResponder()
            return false
        } else {
            capturerResolutionPickerView?.isHidden = true
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in pickerView: UIPickerView) -> Int{
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return capturerResolutions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return capturerResolutionToString(capturerResolutions[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        capturerResolution!.text = capturerResolutionToString(capturerResolutions[row])
        selectedCapturerResolution = capturerResolutions[row]
        
        capturerResolutionPickerView?.isHidden = true
    }
    
    func capturerResolutionToString(_ level: OTCameraCaptureResolution) -> String
    {
        switch level {
        case OTCameraCaptureResolution.low: return "Low (QVGA)"
        case OTCameraCaptureResolution.medium: return "Medium (VGA)"
        case OTCameraCaptureResolution.high: return "High (HD)"
        }
    }
}

