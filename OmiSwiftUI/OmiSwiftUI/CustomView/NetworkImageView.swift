//
//  NetworkImageView.swift
//  OmiSwiftUI
//
//  Created by PRO 2019 16' on 24/05/2023.
//

import Foundation
import SwiftUI

struct CustomImageView: View {
    var urlString: String
    var placeHolder: String
    var width: CGFloat
    var height: CGFloat
    var borderRadius: CGFloat
    
    @ObservedObject var imageLoader = ImageLoaderService()
    @State var image: UIImage = UIImage()
    
    init(urlString: String, placeHolder: String, width: CGFloat, height: CGFloat, borderRadius: CGFloat) {
        self.urlString = urlString
        self.placeHolder = placeHolder
        self.width = width
        self.height = height
        self.borderRadius = borderRadius
        if placeHolder.isEmpty == false {
            image = UIImage(named: placeHolder)!
        }
    }
    
    var body: some View {
        if urlString.isEmpty {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        } else {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .cornerRadius(borderRadius)
                .onReceive(imageLoader.$image) { image in
                    if (image != nil) {
                        self.image = image!
                    }
                }
                .onAppear {
                    imageLoader.loadImage(for: urlString)
                }
        }
    }
}


class ImageLoaderService: ObservableObject {
    @Published var image: UIImage?
    
    func loadImage(for urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.image = UIImage(data: data) ?? UIImage()
            }
        }
        task.resume()
    }
    
}
