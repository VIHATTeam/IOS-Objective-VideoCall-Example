//
//  HomeViewController.swift
//  OmicallDevSwift
//
//  Created by PRO 2019 16' on 18/05/2023.
//

import UIKit
import OmiKit

class HomeViewController: UIViewController {
    
    let USER_NAME1 = "102"
    let PASS_WORD1 = "AwiZHdm2SY"
    let USER_NAME2 = "103"
    let PASS_WORD2 = "a7JoGYJbJQ"

    @IBOutlet weak var tfSipUuid: UITextField!
    
    @IBAction func audioCall(_ sender: Any) {
        OmiClient.startCall(tfSipUuid.text ?? "", isVideo: false) { status in
            if (status == .startCallSuccess) {
                DispatchQueue.main.async {
                    let vc = AudioCallViewController()
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                }
            }
        }
    }
    
    @IBAction func videoCall(_ sender: Any) {
        OmiClient.startCall(tfSipUuid.text ?? "", isVideo: true) { status in
            if (status == .startCallSuccess) {
                DispatchQueue.main.async {
                    let vc = VideoCallViewController()
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                }
            }
        }
    }
    
    @IBAction func loginWithUser1(_ sender: Any) {
        OmiClient.initWithUsername(USER_NAME1, password: PASS_WORD1, realm: "")
        tfSipUuid.text = USER_NAME2
    }
    
    @IBAction func loginWithUser2(_ sender: Any) {
        OmiClient.initWithUsername(USER_NAME2, password: PASS_WORD2, realm: "")
        tfSipUuid.text = USER_NAME1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(callStateChanged), name: NSNotification.Name.OMICallStateChanged, object: nil)
    }
    
    @objc func callStateChanged(notification: NSNotification) {
        DispatchQueue.main.async {
            if let call = notification.userInfo?[OMINotificationUserInfoCallKey] as? OMICall {
                switch (call.callState) {
                case .incoming:
                    var vc : UIViewController!
                    if (call.isVideo) {
                        vc = VideoCallViewController()
                    } else {
                        vc = AudioCallViewController()
                    }
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                    break
                default:
                    break
                }
            }
        }
    }
}
