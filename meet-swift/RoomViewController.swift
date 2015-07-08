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
    @IBOutlet weak var backgroundView :UIView?;
    @IBOutlet weak var publisherView :UIView?;
    
    var session: OTSession?
    var publisher: OTPublisher?
    var subscribers = Dictionary<String, OTSubscriber>()
    
    var roomInfo: RoomInfo?
    
    var disconnectingAlert : UIAlertView?;
    var connectingAlert: UIAlertView?;

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var error:OTError?
        
        session = OTSession(apiKey: roomInfo!.apiKey,
            sessionId: roomInfo!.sessionId,
            delegate: self)
        session!.connectWithToken(roomInfo!.token,
            error: &error)
        
        publisher = OTPublisher(delegate: self, name: roomInfo!.userName, audioTrack: true, videoTrack: true);
        
        self.connectingAlert = UIAlertView(title: "Connecting to session", message: "Connecting to session...", delegate: nil, cancelButtonTitle: nil);
        self.connectingAlert?.show();

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchCameraPressed(sender: AnyObject) {

    }
    
    @IBAction func mutePressed(sender: AnyObject) {

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
    // Session Delegate
    
    func sessionDidConnect(session: OTSession!) {
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
        subscribers[stream.streamId] = subscriber
    }
    
    func session(session: OTSession!, streamDestroyed stream: OTStream!) {}
    
    // Publisher delegate
    func publisher(publisher: OTPublisherKit!, didFailWithError error: OTError!) {}
    
    func publisher(publisher: OTPublisherKit!, streamCreated stream: OTStream!) {
        // Add view
        let pubView = self.publisher?.view;
        pubView?.setTranslatesAutoresizingMaskIntoConstraints(false);
        self.publisherView?.addSubview(pubView!);
        
        let constraints = [
            NSLayoutConstraint(
                item: self.publisherView!,
                attribute:NSLayoutAttribute.Left,
                relatedBy: NSLayoutRelation.Equal,
                toItem: pubView!,
                attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: self.publisherView!,
                attribute:NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: pubView!,
                attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: self.publisherView!,
                attribute:NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: pubView!,
                attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0),
            NSLayoutConstraint(
                item: self.publisherView!,
                attribute:NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: pubView!,
                attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        ];

        self.publisherView?.addConstraints(constraints);
    }

    func publisher(publisher: OTPublisherKit!, streamDestroyed stream: OTStream!) {
        // Remove view
    }
    
    // Subscriber delegate
    func subscriberVideoDataReceived(subscriber: OTSubscriber!) {}
    func subscriberDidConnectToStream(subscriber: OTSubscriberKit!) {}
    
    func subscriber(subscriber: OTSubscriberKit!, didFailWithError error: OTError!) {}

}
