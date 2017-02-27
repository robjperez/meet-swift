//
//  RoomViewController.swift
//  meet-swift
//
//  Created by rpc on 19/04/15.
//  Copyright (c) 2015 tokbox. All rights reserved.
//

import UIKit
import OpenTok

class RoomViewController: UIViewController,
            OTSessionDelegate, OTPublisherDelegate, OTSubscriberDelegate
{
    @IBOutlet weak var publisherView: UIView?
    @IBOutlet weak var statusBar: UIView?
    
    @IBOutlet weak var muteButton: UIButton?
    @IBOutlet weak var cameraButton: UIButton?
    
    @IBOutlet weak var roomName: UILabel?
    @IBOutlet weak var numberOfStreams: UILabel?
    
    @IBOutlet weak var muteSubscriber: UIButton?
    
    var reconnectingAlertDialog : UIAlertView?
    
    var session: OTSession?
    var publisher: OTPublisher?
    
    var roomInfo: RoomInfo!
    
    var disconnectingAlert : UIAlertView?
    var connectingAlert: UIAlertView?
    
    var wasSubscribingToVideo = false
    var wasPublishingVideo = false
    
    var subscriberSimulcastEnabled = false
    
    var viewManager : ViewManager?
    
    var subscriberList = Dictionary<String, OTSubscriber>()
    
    var statsView : UIView?
    
    var roomTapGestureRecognizer : UITapGestureRecognizer?
    
    var selectedCapturerResolution = OTCameraCaptureResolution.medium
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var error:OTError?
        
        session = OTSession(apiKey: roomInfo.apiKey,
            sessionId: roomInfo.sessionId,
            delegate: self)
        
        if subscriberSimulcastEnabled {
            viewManager = MultiSubViewManager(frame: self.view.frame, rootView: self.view)
        } else {
            viewManager = SingleSubViewManager(frame: self.view.frame, rootView: self.view)
        }
        
        self.view.insertSubview(viewManager!, belowSubview: self.statusBar!)
        session!.connect(withToken: roomInfo.token,
            error: &error)
        
        publisher = OTPublisher(delegate: self, name: roomInfo.userName,
            cameraResolution: self.selectedCapturerResolution,
            cameraFrameRate: OTCameraCaptureFrameRate.rate30FPS)
        
        self.connectingAlert = UIAlertView(title: "Connecting to session", message: "Connecting to session...", delegate: nil, cancelButtonTitle: nil)
        self.connectingAlert?.show()
        
        self.roomName?.text = roomInfo.roomName
        self.numberOfStreams?.text = "👥 1"
        
        self.muteSubscriber?.isHidden = true
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(RoomViewController.onEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RoomViewController.onEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        roomTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RoomViewController.handleRoomNameTap(_:)))
        roomTapGestureRecognizer?.numberOfTapsRequired = 2
        roomName?.addGestureRecognizer(roomTapGestureRecognizer!)
        
        reconnectingAlertDialog = UIAlertView(title: "Session is reconnecting", message: "Please wait until we try to restablish your session", delegate: nil, cancelButtonTitle: nil)

    }
    
    @IBAction func switchCameraPressed(_ sender: AnyObject?) {
        if self.publisher?.cameraPosition == AVCaptureDevicePosition.back {
            self.publisher?.cameraPosition = AVCaptureDevicePosition.front
        } else {
            self.publisher?.cameraPosition = AVCaptureDevicePosition.back
        }
    }
    
    @IBAction func mutePressed(_ sender: AnyObject?) {
        self.publisher!.publishAudio = !(self.publisher!.publishAudio)
        (sender as! UIButton).isSelected = !self.publisher!.publishAudio
        NSLog("selected" + (sender as! UIButton).isSelected.description)
    }

    @IBAction func endCallPressed(_ sender: AnyObject) {
        var error : OTError?
        if self.session?.sessionConnectionStatus == OTSessionConnectionStatus.connected ||
            self.session?.sessionConnectionStatus == OTSessionConnectionStatus.connecting
        {
            self.session?.disconnect(&error)
        
            self.disconnectingAlert = UIAlertView(title: "Disconnecting", message: "Disconnecting from session...", delegate: nil, cancelButtonTitle: nil)
            self.disconnectingAlert?.show()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: Session Delegate
    func sessionDidConnect(_ session: OTSession) {
        print("Session \(session) is connected")
        self.muteButton?.isEnabled = true
        self.cameraButton?.isEnabled = true
        
        self.connectingAlert?.dismiss(withClickedButtonIndex: 0, animated: true)
        var error: OTError?
        session.publish(publisher!, error: &error)
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session \(session) is disconnected")
        self.disconnectingAlert?.dismiss(withClickedButtonIndex: 0, animated: false)
        self.dismiss(animated: true, completion: nil)
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("Session \(session) error: \(error)")
        
        reconnectingAlertDialog?.dismiss(withClickedButtonIndex: 0, animated: true)
        self.connectingAlert?.dismiss(withClickedButtonIndex: 0, animated: true)
        
        let errorAc = UIAlertController(
            title: "Error connecting",
            message: "There was an error trying to join the session: \(error.localizedDescription)",
            preferredStyle: .alert)
        errorAc.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in self.dismiss(animated: true, completion: nil) } ))
        present(errorAc, animated: true, completion: nil)
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        let subscriber = OTSubscriber(stream: stream, delegate: self)
        var error: OTError?
        self.session?.subscribe(subscriber!, error: &error)
        
        subscriberList[stream.streamId] = subscriber
        
        updateParticipants(true)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        viewManager!.removeSubscriber(stream.streamId)
        subscriberList.removeValue(forKey: stream.streamId)
        updateParticipants(false)
    }
    
    func sessionDidBeginReconnecting(_ session: OTSession) {
        reconnectingAlertDialog?.show()
    }
    
    func sessionDidReconnect(_ session: OTSession) {
        reconnectingAlertDialog?.dismiss(withClickedButtonIndex: 0, animated: true)
    }
    
    // MARK: Publisher Delegate
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {}
    
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        // Add view
        let pubView = self.publisher?.view
        ViewUtils.addViewFill(pubView!, rootView: self.publisherView!)
    }

    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        // Remove view
    }
    
    // MARK: Subscriber Delegate
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
        
    }
    
    func subscriberDidConnect(toStream subscriber: OTSubscriberKit) {
        if let sub = subscriberList[subscriber.stream!.streamId] {
            viewManager?.addSubscriber(sub,
                streamKey: subscriber.stream!.streamId)
        }
    }
    
    func subscriberDidDisconnect(fromStream subscriber: OTSubscriberKit) {
        print("Subscriber disconnected")
    }
    
    func subscriberDidReconnect(toStream subscriber: OTSubscriberKit) {
        print("Subscriber reconnected")
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {}
    
    func subscriberVideoDisabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {        
        viewManager?.subscriberVideoDisabled(subscriber.stream!.streamId)
    }
    
    func subscriberVideoEnabled(_ subscriber: OTSubscriberKit, reason: OTSubscriberVideoEventReason) {
        viewManager?.subscriberVideoEnabled(subscriber.stream!.streamId)
    }
    
    fileprivate func updateParticipants(_ increment: Bool) {
        if let currentNumber = self.numberOfStreams?.text {
            let number = Int(currentNumber.substring(from: currentNumber.characters.index(currentNumber.startIndex, offsetBy: 2)))
            let text = "👥 " + (increment ? number!+1 : number!-1).description
            self.numberOfStreams!.text = text
        }
    }
    
    func onEnterBackground() {
        if let pub = self.publisher {
            self.wasPublishingVideo = pub.publishVideo
            pub.publishVideo = false
        }

        viewManager!.onEnterBackground()
    }
    
    func onEnterForeground() {
        if let pub = self.publisher {
            pub.publishVideo = self.wasPublishingVideo
        }
        
        viewManager!.onEnterForeground()
    }
    
    func handleRoomNameTap(_ tapRecognizer: UITapGestureRecognizer) {
        if let stats = statsView {
            stats.removeFromSuperview()
            self.statsView = nil
        } else {
            statsView = StatsView(frame: CGRect(x: 0, y: self.view.frame.size.height - 200, width: self.view.frame.size.width, height: 200))
            self.view.addSubview(statsView!)
        }
    }

}
