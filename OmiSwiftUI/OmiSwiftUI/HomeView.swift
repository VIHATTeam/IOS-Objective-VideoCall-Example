//
//  HomeView.swift
//  OmiSwiftUI
//
//  Created by PRO 2019 16' on 23/05/2023.
//

import SwiftUI
import OmiKit

struct HomeView : View {
    
    let USER_NAME1 = "110"
    let PASS_WORD1 = "JuFp30uvwF"
    let USER_NAME2 = "115"
    let PASS_WORD2 = "VlAkzpm2Fn"

    @State private var sip: String = ""
    @State private var showAudioCall = false
    @State private var showVideoCall = false
    
    var body: some View {
        VStack {
            TextField("Enter your sip/uuid", text: $sip)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray,lineWidth: 1)
                )
                .padding(8)
            HStack(alignment: .center, spacing: 24) {
                Button("Audio Call") {
                    OmiClient.startCall(sip)
                    showAudioCall = true
                }.frame(maxWidth: .infinity)
                Button("Video Call") {
                    OmiClient.startVideoCall(sip)
                    showVideoCall = true
                }.frame(maxWidth: .infinity)
            }.frame(
                maxWidth: .infinity,
                maxHeight: 60
              )
            HStack(alignment: .center, spacing: 24) {
                Button("Login User 1") {
                    OmiClient.initWithUsername(USER_NAME1, password: PASS_WORD1, realm: "thaonguyennguyen1197")
                    sip = USER_NAME2
                }.frame(maxWidth: .infinity)
                Button("Login User 2") {
                    OmiClient.initWithUsername(USER_NAME2, password: PASS_WORD2, realm: "thaonguyennguyen1197")
                    sip = USER_NAME1
                }.frame(maxWidth: .infinity)
            }.frame(
                maxWidth: .infinity,
                maxHeight: 60
              )
        }.onViewDidLoad {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.OMICallStateChanged, object: nil, queue: .main, using: self.callStateChanged)
        }.sheet(isPresented: $showAudioCall) {
            AudioCallView()
        }.sheet(isPresented: $showVideoCall) {
            VideoCallView()
        }
    }
    
    func callStateChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            if let call = notification.userInfo?[OMINotificationUserInfoCallKey] as? OMICall {
                switch (call.callState) {
                case .incoming:
                    if (call.isVideo) {
                        showVideoCall = true
                    } else {
                        showAudioCall = true
                    }
                    break
                default:
                    break
                }
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("iPhone 14")
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
