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
    @IBOutlet weak var backgroundView :UIView?
    @IBOutlet weak var publisherView :UIView?
    
    @IBOutlet weak var previousSub: UIButton?
    @IBOutlet weak var nextSub: UIButton?
    
    @IBOutlet weak var muteButton: UIButton?
    @IBOutlet weak var cameraButton: UIButton?
    
    @IBOutlet weak var roomName: UILabel?
    @IBOutlet weak var numberOfStreams: UILabel?
    
    @IBOutlet weak var muteSubscriber: UIButton?
    
    var session: OTSession?
    var publisher: OTPublisher?
    var subscribers = Dictionary<String, OTSubscriber>()
    var selectedSubscriber : String?
    
    var roomInfo: RoomInfo?
    
    var disconnectingAlert : UIAlertView?
    var connectingAlert: UIAlertView?
    
    var wasSubscribingToVideo = false
    var wasPublishingVideo = false
    
    var simulcastLevel: OTPublisherKitSimulcastLevel = OTPublisherKitSimulcastLevel.LevelNone;

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
        if let dict = envs {
            envUrl = NSURL(string: envs?.objectForKey("meet") as! String)
        }
        
        session!.setApiRootURL(envUrl)
        session!.connectWithToken(roomInfo!.token,
            error: &error)
        
        publisher = OTPublisher(delegate: self, name: roomInfo!.userName, audioTrack: true, videoTrack: true, simulcastLevel:self.simulcastLevel);
        
        self.connectingAlert = UIAlertView(title: "Connecting to session", message: "Connecting to session...", delegate: nil, cancelButtonTitle: nil);
        self.connectingAlert?.show()
        
        self.roomName?.text = roomInfo!.roomName
        self.numberOfStreams?.text = "👥 1"
        
        self.muteSubscriber?.hidden = true
        
        UIApplication.sharedApplication().idleTimerDisabled = true;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)

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
    
    @IBAction func nextSubPresseed(sender: AnyObject?) {
        if self.subscribers.count <= 1 { return }
        
        let sortedKeys = Array(self.subscribers.keys).sorted(<)
        let currentIndex = find(sortedKeys, self.selectedSubscriber!)
        let nextIndex = (currentIndex! + 1) % self.subscribers.count
        let nextKey = sortedKeys[nextIndex]
        
        self.performSubscriberAnimation(self.subscribers[nextKey]!.stream.streamId)
    }
    
    @IBAction func prevSubPresseed(sender: AnyObject) {
        if self.subscribers.count <= 1 { return }
        
        let sortedKeys = Array(self.subscribers.keys).sorted(<)
        let currentIndex = find(sortedKeys, self.selectedSubscriber!)
        var nextIndex = 0
        if currentIndex == 0 { nextIndex = self.subscribers.count - 1}
        else { nextIndex = currentIndex! - 1 }
        let nextKey = sortedKeys[nextIndex]
        
        self.performSubscriberAnimation(self.subscribers[nextKey]!.stream.streamId)
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
        var subscriber = OTSubscriber(stream: stream, delegate: self)
        var error: OTError?
        subscribers[stream.streamId] = subscriber
        self.toggleSubsButtons()
        self.session?.subscribe(subscriber, error: &error)
        
        updateParticipants(true)
    }
    
    func session(session: OTSession!, streamDestroyed stream: OTStream!) {
        self.nextSubPresseed(nil)
        self.subscribers.removeValueForKey(stream.streamId)
        toggleSubsButtons()
        
        updateParticipants(false)
    }
    
    // MARK: Publisher Delegate
    func publisher(publisher: OTPublisherKit!, didFailWithError error: OTError!) {}
    
    func publisher(publisher: OTPublisherKit!, streamCreated stream: OTStream!) {
        // Add view
        let pubView = self.publisher?.view;
        self.addVideoView(pubView, container: self.publisherView)
    }

    func publisher(publisher: OTPublisherKit!, streamDestroyed stream: OTStream!) {
        // Remove view
    }
    
    // MARK: Subscriber Delegate
    func subscriberVideoDataReceived(subscriber: OTSubscriber!) {
        
    }
    
    func subscriberDidConnectToStream(subscriber: OTSubscriberKit!) {
        let sub = self.subscribers[subscriber.stream.streamId];
        let subView = sub?.view;
        
        if self.subscribers.count > 1 && self.selectedSubscriber != nil {
            self.performSubscriberAnimation(subscriber.stream.streamId)
        } else {
            self.addVideoView(subView, container: self.view, atIndex: 0)
        }
        
        self.selectedSubscriber = subscriber.stream.streamId
    }
    
    func subscriber(subscriber: OTSubscriberKit!, didFailWithError error: OTError!) {}
    
    private func performSubscriberAnimation(subId: String) {
        if selectedSubscriber == subId { return }
        
        let previousSubscriber = self.subscribers[self.selectedSubscriber!]
        let newSubscriber = self.subscribers[subId]!
        
        newSubscriber.view.alpha = 0.0
        self.addVideoView(newSubscriber.view, container: self.view, atIndex: 0)
        
        previousSubscriber?.subscribeToVideo = false
        newSubscriber.subscribeToVideo = true
        
        UIView.animateWithDuration(0.4,
            animations: { () -> Void in
                previousSubscriber?.view.alpha = 0.0
                newSubscriber.view.alpha = 1.0
            },
            completion: { (finished) -> Void in
                self.selectedSubscriber = subId
                previousSubscriber?.view.removeFromSuperview()
            })
    }
    
    // MARK: Private methods
    private func addVideoView(videoView: UIView?, container:UIView?, atIndex: Int? = nil) {
        videoView?.setTranslatesAutoresizingMaskIntoConstraints(false)
        if let unwrappedIndex = atIndex {
            container?.insertSubview(videoView!, atIndex: unwrappedIndex)
        } else {
            container?.addSubview(videoView!)
        }
        
        let constraints = [
            NSLayoutConstraint(
                item:container!,
                attribute:NSLayoutAttribute.Left,
                relatedBy: NSLayoutRelation.Equal,
                toItem: videoView!,
                attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: container!,
                attribute:NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: videoView!,
                attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: container!,
                attribute:NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: videoView!,
                attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: container!,
                attribute:NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: videoView!,
                attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        ];
        
        container?.addConstraints(constraints)
    }
    
    private func toggleSubsButtons() {
        if self.subscribers.count > 1 {
            self.previousSub?.hidden = false
            self.nextSub?.hidden = false
        } else {
            self.previousSub?.hidden = true
            self.nextSub?.hidden = true
        }
    }
    
    private func updateParticipants(increment: Bool) {
        if let currentNumber = self.numberOfStreams?.text {
            let number = currentNumber.substringFromIndex(advance(currentNumber.startIndex, 2)).toInt()!
            let text = "👥 " + (increment ? number+1 : number-1).description
            self.numberOfStreams!.text = text
        }
    }
    
    func onEnterBackground() {
        if let pub = self.publisher {
            self.wasPublishingVideo = pub.publishVideo
            pub.publishVideo = false
        }

        if let subId = self.selectedSubscriber {
            let sub = self.subscribers[subId]
            if let videoEnabled = sub?.subscribeToVideo {
                self.wasPublishingVideo = videoEnabled
            }
            
            sub?.subscribeToVideo = false
        }

    }
    
    func onEnterForeground() {
        if let pub = self.publisher {
            pub.publishVideo = self.wasPublishingVideo
        }
        
        if let subId = self.selectedSubscriber {
            let sub = self.subscribers[subId]
            sub?.subscribeToVideo = self.wasSubscribingToVideo
        }
    }

}
