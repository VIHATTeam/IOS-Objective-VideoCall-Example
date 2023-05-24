//
//  VideoCallView.swift
//  OmiSwiftUI
//
//  Created by PRO 2019 16' on 23/05/2023.
//

import SwiftUI
import OmiKit

struct VideoCallView: View {
    
    @Binding var phone: String
    @Environment(\.presentationMode) var presentationMode
    @State var establishedCall = false
    @State var muted = false
    @State var isCameraOn = true
    @State var remoteView : UIView? = nil
    @State var localView : UIView? = nil
    @State var networkImage = "network_best"
    
    var body: some View {
        ZStack {
            if (remoteView != nil) {
                CameraView(video: remoteView!)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
            VStack {
                Spacer()
                HStack(spacing: 32) {
                    if (establishedCall) {
                        Button {
                            OmiVideoUtils.videoManager.toggleCamera()
                            isCameraOn = OmiVideoUtils.videoManager.isCameraOn
                        } label: {
                            Image(uiImage: UIImage(named: isCameraOn ? "video" : "video-off")!)
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
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
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(uiImage: UIImage(named: "hangup")!)
                            .resizable()
                            .frame(width: 60, height: 60)
                    }
                }
                Spacer().frame(height: 32)
            }
            if (localView != nil) {
                VStack(alignment: .center) {
                    Button {
                        OmiVideoUtils.videoManager.switchCamera()
                    } label: {
                        Image(uiImage: UIImage.init(named: "refresh")!)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    Spacer().frame(height: 16)
                    CameraView(video: localView!)
                        .frame(width: 90, height: 160)
                }.position(x: UIScreen.main.bounds.size.width - 45 - 24, y: 24 + 100)
            }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .center
        ).onViewDidLoad {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallStateChanged, object: nil, queue: .main, using: self.callStateChanged)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallDealloc, object: nil, queue: .main, using: self.callDealloc)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallNetworkQuality, object: nil, queue: .main, using: self.updateNetworkHealth)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallVideoInfo, object: nil, queue: .main, using: self.videoNotification)
        }.onAppear{
            AVCaptureDevice.requestAccess(for: .video) { _ in
                
            }
        }.onDisappear {
            NotificationCenter.default.removeObserver(self)
            OmiVideoUtils.videoManager = OMIVideoViewManager()
        }
    }
    
    func videoNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo, let state = userInfo[OMIVideoInfoState] as? Int {
            if state == 1 {
                startPreview()
            }
        }
    }
    
    private func startPreview() {
        let screenSize = UIScreen.main.bounds.size
        remoteView = OmiVideoUtils.videoManager.createView(forVideoRemote: CGRect.init(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        localView = OmiVideoUtils.videoManager.createView(forVideoLocal: CGRect.init(x: 0, y: 0, width: 90, height: 160))
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

struct VideoCallView_Previews: PreviewProvider {
    @State static var phone = "110"
    static var previews: some View {
        VideoCallView(phone: $phone)
    }
}
