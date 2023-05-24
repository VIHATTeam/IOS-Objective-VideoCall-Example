//
//  LocalCameraView.swift
//  OmiSwiftUI
//
//  Created by PRO 2019 16' on 24/05/2023.
//

import SwiftUI
import OmiKit

struct CameraView : UIViewRepresentable {
    
    @State var video : UIView = UIView()
    typealias UIViewType = OMIVideoPreviewView
    
    func makeUIView(context: Context) -> OMIVideoPreviewView {
        let view = OMIVideoPreviewView()
        view.contentMode = .scaleAspectFill
        return view
    }
    
    func updateUIView(_ uiView: OMIVideoPreviewView, context: Context) {
        uiView.setView(video)
    }
}
