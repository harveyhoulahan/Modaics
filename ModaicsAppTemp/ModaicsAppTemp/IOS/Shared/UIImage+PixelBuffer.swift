//
//  UIImage+PixelBuffer.swift
//  ModaicsAppTemp
//
//  Created by Harvey Houlahan on 6/6/2025.
//


import UIKit
import CoreVideo

extension UIImage {
    /// Resize (if needed) and convert the image into a Core ML-ready
    /// 224 × 224 `CVPixelBuffer` in BGRA format.
    func pixelBuffer(size: CGSize = CGSize(width: 224, height: 224)) -> CVPixelBuffer? {

        // 1 – Draw into 224×224 bitmap context
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        self.draw(in: CGRect(origin: .zero, size: size))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext(); return nil
        }
        UIGraphicsEndImageContext()

        // 2 – Create an empty pixel buffer
        var buffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let ok = CVPixelBufferCreate(kCFAllocatorDefault,
                                     Int(size.width), Int(size.height),
                                     kCVPixelFormatType_32BGRA,
                                     attrs as CFDictionary, &buffer)
        guard ok == kCVReturnSuccess, let pixelBuffer = buffer else { return nil }

        // 3 – Render the CGImage into the pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        if let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                               width: Int(size.width),
                               height: Int(size.height),
                               bitsPerComponent: 8,
                               bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) {
            ctx.draw(resized, in: CGRect(x: 0, y: 0,
                                         width: size.width, height: size.height))
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        return pixelBuffer
    }
}
