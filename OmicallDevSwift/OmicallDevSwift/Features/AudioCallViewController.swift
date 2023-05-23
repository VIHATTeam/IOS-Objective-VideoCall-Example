//
//  AudioCallViewController.swift
//  OmicallDevSwift
//
//  Created by PRO 2019 16' on 23/05/2023.
//

import UIKit
import OmiKit
import SDWebImage

class AudioCallViewController: UIViewController {

    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var imgSpeaker: UIImageView!
    @IBOutlet weak var imgMic: UIImageView!
    @IBOutlet weak var imgHangUp: UIImageView!
    @IBOutlet weak var imgNetwork: UIImageView!
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgPickUp: UIImageView!
    var timer: Timer?
    var isSpeaker = false
    var currentTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNotification()
        getUserInfor()
        imgPickUp.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickCall)))
        imgHangUp.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endCall)))
        imgMic.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleMic)))
        imgSpeaker.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleSpeaker)))
        imgAvatar.layer.cornerRadius = 50
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if (timer != nil) {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func runTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            //show timer
            guard let self = self else { return }
            self.currentTime += 1
            self.lblTimer.text = self.currentTime.toHour()
        }
    }
    
    private func getUserInfor() {
        guard let call = OMISIPLib.sharedInstance().getNewestCall() as? OMICall else {
            return
        }
        let number = call.callerNumber
        lblTitle.text = "Cuộc gọi tới từ: \(number!)"
        if let user = OmiClient.getAccountInfo(number ?? "") as? [String: Any], let avatar = user["avatar_url"] as? String {
            imgAvatar.sd_setImage(with: URL(string: "https://imglarger.com/Images/before-after/ai-image-enlarger-1-after-2.jpg")!)
            if (avatar.isEmpty == false) {
                //load avatar
            }
        }
    }
    
    private func setUpNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(callStateChanged), name: NSNotification.Name.OMICallStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callDealloc), name: NSNotification.Name.OMICallDealloc, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateNetworkHealth), name: NSNotification.Name.OMICallNetworkQuality, object: nil)
    }
    
    @objc func callStateChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: Any], let call = userInfo[OMINotificationUserInfoCallKey] as? OMICall {
            if call.callState == .confirmed {
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.setUIFromStatus(joinedCall: true)
                    //load timer
                    self.runTimer()
                }
            }
            if call.callState == .disconnected {
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.dismiss(animated: true)
                }
                return
            }
        }
    }
    
    @objc func callDealloc(notification: NSNotification) {
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
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
    
    private func setUIFromStatus(joinedCall: Bool) {
        if (joinedCall) {
            imgPickUp.isHidden = true
            imgMic.isHidden = false
            imgSpeaker.isHidden = false
            imgNetwork.isHidden = false
        } else {
            imgPickUp.isHidden = false
            imgSpeaker.isHidden = true
            imgMic.isHidden = true
            imgNetwork.isHidden = true
        }
    }
    
    @objc func toggleSpeaker() {
        if !isSpeaker {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } else {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        }
        isSpeaker = !isSpeaker
    }
    
    @objc func toggleMic() {
        if let call = OMISIPLib.sharedInstance().getCurrentConfirmCall() {
            try? call.toggleMute()
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                let muted = call.muted
                self.imgMic.image = UIImage.init(named: muted ? "mic-off": "mic")
            }
        }
    }
    
    @objc func pickCall() {
        if let call = OMISIPLib.sharedInstance().getNewestCall() {
            OmiClient.answerIncommingCall(call.uuid)
        }
    }
    
    @objc func endCall() {
        OMISIPLib.sharedInstance().callManager.endActiveCall()
        DispatchQueue.main.async {[weak self] in
            guard let self = self else {
                return
            }
            self.dismiss(animated: true)
        }
    }
}


extension Int {
    func toHour() -> String {
        let second = self % 60
        let minute = self / 60
        var secondString = "\(second)"
        var minuteString = "\(minute)"
        if (second < 10) {
            secondString = "0\(second)"
        }
        if (minute < 10) {
            minuteString = "0\(minute)"
        }
        return "\(minuteString):\(secondString)"
    }
}
