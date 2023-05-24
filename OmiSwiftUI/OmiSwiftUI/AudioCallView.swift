//
//  AudioCallView.swift
//  OmiSwiftUI
//
//  Created by PRO 2019 16' on 23/05/2023.
//

import SwiftUI
import OmiKit

struct AudioCallView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var establishedCall = false
    @State var networkImage = "network_best"
    @State var userImage = ""
    @State var muted = false
    @State var isSpeaker = false
    
    private func incomingNumber() -> String {
        if let call = OMISIPLib.sharedInstance().getNewestCall() {
            return call.callerNumber ?? ""
        }
        return ""
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                CustomImageView(urlString: userImage, placeHolder: "avt", width: 100, height: 100, borderRadius: 50)
                Spacer().frame(height: 24)
                Text("Cuộc gọi tới từ \(incomingNumber())")
                Spacer()
                HStack(spacing: 32) {
                    if (establishedCall) {
                        Button {
                            if let call = OMISIPLib.sharedInstance().getCurrentConfirmCall() {
                                try? call.toggleMute()
                                DispatchQueue.main.async {
                                    self.muted = call.muted
                                }
                            }
                        } label: {
                            Image(uiImage: UIImage(named: muted ? "mic-off" : "mic")!)
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        Button {
                            if !isSpeaker {
                                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                            } else {
                                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                            }
                            isSpeaker = !isSpeaker
                        } label: {
                            Image(uiImage: UIImage(named: isSpeaker ? "mic" : "mic-off")!)
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                    } else {
                        Button {
                            if let call = OMISIPLib.sharedInstance().getNewestCall() {
                                OmiClient.answerIncommingCall(call.uuid)
                            }
                        } label: {
                            Image(uiImage: UIImage(named: "Image")!)
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                    }
                    Button {
                        OMISIPLib.sharedInstance().callManager.endActiveCall()
                        DispatchQueue.main.async {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Image(uiImage: UIImage(named: "hangup")!)
                            .resizable()
                            .frame(width: 60, height: 60)
                    }
                }
                Spacer().frame(height: 32)
            }
            Image(uiImage: UIImage.init(named: networkImage)!)
                .resizable()
                .frame(width: 24, height: 24).position(x: 24, y: 24)
        }.frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        ).padding(16)
        .onViewDidLoad {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallStateChanged, object: nil, queue: .main, using: self.callStateChanged)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallDealloc, object: nil, queue: .main, using: self.callDealloc)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallNetworkQuality, object: nil, queue: .main, using: self.updateNetworkHealth)
        }.onDisappear {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OMICallDealloc, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OMICallNetworkQuality, object: nil)
        }.onAppear {
            getUserInfo()
        }
    }
    
    private func getUserInfo() {
        let fromPhone = incomingNumber()
        if fromPhone.isEmpty == false {
            if let user = OmiClient.getAccountInfo(fromPhone) as? [String: Any], let avatar = user["avatar_url"] as? String {
//                userImage = avatar
                userImage = "https://imglarger.com/Images/before-after/ai-image-enlarger-1-after-2.jpg"
            }
        }
    }
    
    func callStateChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            if let call = notification.userInfo?[OMINotificationUserInfoCallKey] as? OMICall {
                switch (call.callState) {
                case .confirmed:
                    self.establishedCall = true
                    break
                case .disconnected:
                    self.presentationMode.wrappedValue.dismiss()
                    break
                default:
                    break
                }
            }
        }
    }
    
    func callDealloc(_ notification: Notification) {
        DispatchQueue.main.async {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func updateNetworkHealth(_ notification: Notification) {
        let userInfo = notification.userInfo
        if let state = userInfo?[OMINotificationNetworkStatusKey] as? Int {
            switch (state) {
            case 0:
                networkImage = "network_best"
                break
            case 1:
                networkImage = "network_medium"
                break
            case 2:
                networkImage = "network_bad"
                break
            default:
                break
            }
        }
    }
}

struct AudioCallView_Previews: PreviewProvider {
    static var previews: some View {
        AudioCallView()
    }
}
