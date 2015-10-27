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
    
    var session: OTSession?
    var publisher: OTPublisher?
    
    var roomInfo: RoomInfo?
    
    var disconnectingAlert : UIAlertView?
    var connectingAlert: UIAlertView?
    
    var wasSubscribingToVideo = false
    var wasPublishingVideo = false
    
    var simulcastLevel: OTPublisherKitSimulcastLevel = OTPublisherKitSimulcastLevel.LevelNone
    var simulcastUseCustomValues = false
    var subscriberSimulcastEnabled = false
    
    var viewManager : ViewManager?
    
    var subscriberList = Dictionary<String, OTSubscriber>()
    
    var statsView : UIView?
    
    var roomTapGestureRecognizer : UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var error:OTError?
        
        session = OTSession(apiKey: roomInfo!.apiKey,
            sessionId: roomInfo!.sessionId,
            delegate: self)
        
        var envs: NSDictionary?
        var envUrl : NSURL?
        if let path = NSBundle.mainBundle().pathForResource("environment", ofType: "plist") {
            envs = NSDictionary(contentsOfFile: path)
        }
        if let _ = envs {
            envUrl = NSURL(string: envs?.objectForKey("meet") as! String)
        }
        
        if subscriberSimulcastEnabled {
            viewManager = MultiSubViewManager(frame: self.view.frame, rootView: self.view)
        } else {
            viewManager = SingleSubViewManager(frame: self.view.frame, rootView: self.view)
        }
        
        self.view.insertSubview(viewManager!, belowSubview: self.statusBar!)
        
        session!.setApiRootURL(envUrl)
        session!.connectWithToken(roomInfo!.token,
            error: &error)
        
        if self.simulcastLevel != OTPublisherKitSimulcastLevel.LevelNone {
            var cTempAdj: UnsafeMutablePointer<(Float, Float, Float, Float)> = nil
            var maxSpatialLayers : Int32 = 0
            var cTempAdjCount = 0
            
            if simulcastUseCustomValues {
                let tempAdj = [(Float, Float, Float, Float)](count: 4, repeatedValue:(0.1, 1.0, 1.0, 1.0));
                cTempAdjCount = tempAdj.count
                cTempAdj = UnsafeMutablePointer<(Float, Float, Float, Float)>.alloc(cTempAdjCount)
                cTempAdj.initializeFrom(tempAdj)
                
                maxSpatialLayers = 1
            }
            
            publisher = OTPublisher(delegate: self, name: roomInfo!.userName, audioTrack: true, videoTrack: true, simulcastLevel:self.simulcastLevel, maxSpatialLayers: maxSpatialLayers, temporalLayerRateAdjustments: cTempAdj);
            
            if cTempAdjCount > 0 {
                cTempAdj.dealloc(cTempAdjCount)
            }
        } else {
            publisher = OTPublisher(delegate: self, name: roomInfo!.userName, audioTrack: true, videoTrack: true)
        }
        
        if self.simulcastLevel == OTPublisherKitSimulcastLevel.Level720p {
            publisher!.cameraResolution = OTCameraResolutionHigh
        } else {
            publisher!.cameraResolution = OTCameraResolutionDefault
        }
        
        self.connectingAlert = UIAlertView(title: "Connecting to session", message: "Connecting to session...", delegate: nil, cancelButtonTitle: nil);
        self.connectingAlert?.show()
        
        self.roomName?.text = roomInfo!.roomName
        self.numberOfStreams?.text = "👥 1"
        
        self.muteSubscriber?.hidden = true
        
        UIApplication.sharedApplication().idleTimerDisabled = true;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        roomTapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleRoomNameTap:"))
        roomTapGestureRecognizer?.numberOfTapsRequired = 2
        roomName?.addGestureRecognizer(roomTapGestureRecognizer!)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchCameraPressed(sender: AnyObject?) {
        if self.publisher?.cameraPosition == AVCaptureDevicePosition.Back {
            self.publisher?.cameraPosition = AVCaptureDevicePosition.Front
        } else {
            self.publisher?.cameraPosition = AVCaptureDevicePosition.Back
        }
    }
    
    @IBAction func mutePressed(sender: AnyObject?) {
        self.publisher!.publishAudio = !(self.publisher!.publishAudio)
        (sender as! UIButton).selected = !self.publisher!.publishAudio
        NSLog("selected" + (sender as! UIButton).selected.description)
    }

    @IBAction func endCallPressed(sender: AnyObject) {
        var error : OTError?;
        if self.session?.sessionConnectionStatus == OTSessionConnectionStatus.Connected ||
            self.session?.sessionConnectionStatus == OTSessionConnectionStatus.Connecting
        {
            self.session?.disconnect(&error);
        
            self.disconnectingAlert = UIAlertView(title: "Disconnecting", message: "Disconnecting from session...", delegate: nil, cancelButtonTitle: nil);
            self.disconnectingAlert?.show()
        } else {
            self.dismissViewControllerAnimated(true, completion: nil);
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: Session Delegate
    func sessionDidConnect(session: OTSession!) {
        self.muteButton?.enabled = true;
        self.cameraButton?.enabled = true;
        
        self.connectingAlert?.dismissWithClickedButtonIndex(0, animated: true);
        var error: OTError?
        session!.publish(publisher, error: &error)
    }
    
    func sessionDidDisconnect(session: OTSession!) {
        self.disconnectingAlert?.dismissWithClickedButtonIndex(0, animated: false);
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func session(session: OTSession!, didFailWithError error: OTError!) {
            self.connectingAlert?.dismissWithClickedButtonIndex(0, animated: true);
    }
    
    func session(session: OTSession!, streamCreated stream: OTStream!) {
        let subscriber = OTSubscriber(stream: stream, delegate: self)
        var error: OTError?
        self.session?.subscribe(subscriber, error: &error)
        
        subscriberList[stream.streamId] = subscriber
        
        updateParticipants(true)
    }
    
    func session(session: OTSession!, streamDestroyed stream: OTStream!) {
        viewManager!.removeSubscriber(stream.streamId)
        subscriberList.removeValueForKey(stream.streamId)
        updateParticipants(false)
    }
    
    // MARK: Publisher Delegate
    func publisher(publisher: OTPublisherKit!, didFailWithError error: OTError!) {}
    
    func publisher(publisher: OTPublisherKit!, streamCreated stream: OTStream!) {
        // Add view
        let pubView = self.publisher?.view;
        ViewUtils.addViewFill(pubView!, rootView: self.publisherView!)
    }

    func publisher(publisher: OTPublisherKit!, streamDestroyed stream: OTStream!) {
        // Remove view
    }
    
    // MARK: Subscriber Delegate
    func subscriberVideoDataReceived(subscriber: OTSubscriber!) {
        
    }
    
    func subscriberDidConnectToStream(subscriber: OTSubscriberKit!) {
        if let sub = subscriberList[subscriber.stream.streamId] {
            viewManager?.addSubscriber(sub,
                streamKey: subscriber.stream.streamId)
        }
    }
    
    func subscriber(subscriber: OTSubscriberKit!, didFailWithError error: OTError!) {}
    
    func subscriberVideoDisabled(subscriber: OTSubscriberKit!, reason: OTSubscriberVideoEventReason) {
        viewManager?.subscriberVideoDisabled(subscriber.stream.streamId)
    }
    
    func subscriberVideoEnabled(subscriber: OTSubscriberKit!, reason: OTSubscriberVideoEventReason) {
        viewManager?.subscriberVideoEnabled(subscriber.stream.streamId)
    }
    
    private func updateParticipants(increment: Bool) {
        if let currentNumber = self.numberOfStreams?.text {
            let number = Int(currentNumber.substringFromIndex(currentNumber.startIndex.advancedBy(2)))
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
    
    func handleRoomNameTap(tapRecognizer: UITapGestureRecognizer) {
        if let stats = statsView {
            stats.removeFromSuperview()
            self.statsView = nil
        } else {
            statsView = StatsView(frame: CGRectMake(0, self.view.frame.size.height - 200, self.view.frame.size.width, 200))
            self.view.addSubview(statsView!)
        }
    }

}
