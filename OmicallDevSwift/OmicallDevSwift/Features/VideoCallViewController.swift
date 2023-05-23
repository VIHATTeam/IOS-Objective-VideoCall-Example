//
//  VideoCallViewController.swift
//  OmicallDevSwift
//
//  Created by PRO 2019 16' on 23/05/2023.
//

import UIKit
import OmiKit
import AVFoundation

class VideoCallViewController: UIViewController {

    @IBOutlet weak var imgSwitch: UIImageView!
    @IBOutlet weak var imgNetwork: UIImageView!
    @IBOutlet weak var imgHangUp: UIImageView!
    @IBOutlet weak var imgMic: UIImageView!
    @IBOutlet weak var imgCamera: UIImageView!
    @IBOutlet weak var localView: OMIVideoPreviewView!
    @IBOutlet weak var remoteView: OMIVideoPreviewView!
    var videoManager: OMIVideoViewManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNotification()
        setUpForCall()
        imgHangUp.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hangUp)))
        imgMic.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mic)))
        imgCamera.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cam)))
        imgSwitch.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(switchCamera)))
    }
    
    private func setUpForCall() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            
        }
        videoManager = OMIVideoViewManager.init()
    }
    
    private func setUpNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(callStateChanged), name: NSNotification.Name.OMICallStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callDealloc), name: NSNotification.Name.OMICallDealloc, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoNotification), name: NSNotification.Name.OMICallVideoInfo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateNetworkHealth), name: NSNotification.Name.OMICallNetworkQuality, object: nil)
    }
    
    @objc func callStateChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: Any], let call = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
            if call.callState == .disconnected {
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    @objc func callDealloc(notification: NSNotification) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
    }
    
    @objc func videoNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo, let state = userInfo[OMIVideoInfoState] as? Int {
            if state == 1 {
                startPreview()
            }
        }
    }
    
    @objc func updateNetworkHealth(notification: NSNotification) {
        let userInfo = notification.userInfo
        if let state = userInfo?[OMINotificationNetworkStatusKey] as? Int {
            switch (state) {
            case 0:
                imgNetwork.image = UIImage.init(named: "network_best")
                break
            case 1:
                imgNetwork.image = UIImage.init(named: "network_medium")
                break
            case 2:
                imgNetwork.image = UIImage.init(named: "network_bad")
                break
            default:
                break
            }
        }
    }
    
    @objc func hangUp() {
        DispatchQueue.main.async {
            OMISIPLib.sharedInstance().callManager.endActiveCall()
            self.dismiss(animated: true)
        }
    }
    
    @objc func switchCamera() {
        videoManager?.switchCamera()
    }
    
    
    @objc func cam() {
        guard let videoManager = videoManager else { return }
        videoManager.toggleCamera()
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.imgCamera.image = UIImage.init(named: videoManager.isCameraOn ? "video" : "video-off")
        }
    }
    
    @objc func mic() {
        if let call = OMISIPLib.sharedInstance().getCurrentConfirmCall() {
            try? call.toggleMute()
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                let muted = call.muted
                self.imgMic.image = UIImage.init(named: muted ? "mic-off": "mic")
            }
        }
    }
    
    private func startPreview() {
        guard let videoManager = videoManager else { return }
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.remoteView.contentMode = .scaleToFill
            self.remoteView.setView(videoManager.createView(forVideoRemote: self.remoteView.frame))
            self.localView.contentMode = .scaleToFill
            self.localView.setView(videoManager.createView(forVideoLocal: self.localView.frame))
        }
    }
}
