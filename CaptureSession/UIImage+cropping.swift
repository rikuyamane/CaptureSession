//
//  UIImage+cropping.swift
//  ARMakunouchi
//
//  Created by YamaneRiku on 2017/06/12.
//  Copyright © 2017年 Riku Yamane. All rights reserved.
//

import UIKit
extension UIImage {
    func cropping(to: CGRect) -> UIImage? {
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                break
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func aspectFillingImage(to:CGSize) -> UIImage? {
        let sourceRatio = size.height / size.width
        let toRatio = to.height / to.width
        
        
        if sourceRatio > toRatio {
            // 幅を揃えて上下を切る
            let toHeight = to.height * size.width / to.width
            let cropRect = CGRect(x: 0, y: (size.height - toHeight) / 2, width: size.width, height: toHeight)
            return cropping(to: cropRect)
        }
        // 左右を切る
        let toWidth = to.width * size.height / to.height
        let cropRect = CGRect(x: (size.width - toWidth) / 2, y: 0, width: toWidth, height: size.height)
        return cropping(to: cropRect)
    }
    
    func composit(image: UIImage, rect: CGRect) -> UIImage? {
        let imageFrame = CGRect(origin: .zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0);
        draw(in: imageFrame)
        
        let ratio = imageFrame.size.width / UIScreen.main.bounds.width
        let drawFrame = CGRect(x: ratio * rect.minX , y: ratio * rect.minY, width: ratio * rect.width, height: ratio * rect.height)
        
        image.draw(in: drawFrame)
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage
    }
}
