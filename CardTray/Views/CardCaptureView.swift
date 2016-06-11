//
//  CardCaptureView.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation

class CardCaptureView: UIView,AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private weak var captureDevice : AVCaptureDevice?
    private weak var captureLayer: AVCaptureVideoPreviewLayer?
    private lazy var sessionQueue: dispatch_queue_t = {
        return dispatch_queue_create("camera capture session", DISPATCH_QUEUE_SERIAL)
    }()
    
    private lazy var bufferQueue: dispatch_queue_t = {
        let q = dispatch_queue_create("camera buffer queue", DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(q, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0))
        return q
    }()

    private lazy var textDetector : CIDetector = {
        let detectorOptions = [
            CIDetectorAccuracy : CIDetectorAccuracyHigh,
            ]
        return CIDetector(ofType: CIDetectorTypeText, context: nil, options: detectorOptions)
    }()
    
    private lazy var tesseract : G8Tesseract = {
        let t = G8Tesseract(language: "eng", engineMode: .TesseractCubeCombined)
        // ABCDEFGHIJKLMNOPQRSTUVWXYZ
        t.charWhitelist = "0123456789"
        t.maximumRecognitionTime = 2
        return t
    }()
    
    private lazy var tesseractFilter : (CIFilter,CIFilter) = {
        //        CIImage *blackAndWhite = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, beginImage, @"inputBrightness", @0.0, @"inputContrast", @1.1, @"inputSaturation", @0.0, nil].outputImage;
        //        CIImage *output = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:kCIInputImageKey, blackAndWhite, @"inputEV", @0.7, nil].outputImage;
        
        let blackAndWhiteFilter = CIFilter(name: "CIColorControls")
        blackAndWhiteFilter?.setValue(NSNumber(float: 0), forKey: "inputBrightness")
        blackAndWhiteFilter?.setValue(NSNumber(float: 1.1), forKey: "inputContrast")
        blackAndWhiteFilter?.setValue(NSNumber(float: 0), forKey: "inputSaturation")
        
        let exposureAdjustFilter = CIFilter(name: "CIExposureAdjust")
        exposureAdjustFilter?.setValue(blackAndWhiteFilter!.outputImage, forKey: kCIInputImageKey)
        exposureAdjustFilter?.setValue(NSNumber(float: 0.7), forKey: "inputEV")
        return (blackAndWhiteFilter!,exposureAdjustFilter!)
    }()

    private var isUsingFrontFacingCamera = false

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    private lazy var focusTapGestureRecognizer : UITapGestureRecognizer = {
        [unowned self] in
        let focusTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.focusTap))
        focusTapGesture.numberOfTapsRequired = 1
        focusTapGesture.numberOfTouchesRequired = 1
        return focusTapGesture
    }()

    func startSession() {
        guard captureSession == nil else {
            NSLog("Session already started")
            return
        }
        
        do {
            let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            let captureInput = try AVCaptureDeviceInput(device: captureDevice)
            let session = AVCaptureSession()
            session.addInput(captureInput)
            
            try captureDevice.lockForConfiguration()
            defer {
                captureDevice.unlockForConfiguration()
            }
            
            captureDevice.focusMode = .ContinuousAutoFocus
            captureDevice.exposureMode = .ContinuousAutoExposure
            
            // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
            // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
            // see the header doc for setSampleBufferDelegate:queue: for more information
            let videoDataOutput = AVCaptureVideoDataOutput()
            
            // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
            let rgbOutputSettings = [
                kCVPixelBufferPixelFormatTypeKey as NSString : NSNumber(unsignedInt: kCMPixelFormat_32BGRA)
            ]
            videoDataOutput.videoSettings = rgbOutputSettings
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: self.bufferQueue)
            session.addOutput(videoDataOutput)
            //            videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = false
            
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            if let existingLayer = self.captureLayer {
                existingLayer.performSelector(#selector(existingLayer.removeFromSuperlayer), withObject:nil, afterDelay:0)
            }
            let view = self;
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, atIndex: 0)
            self.captureLayer = layer
            
            dispatch_async(self.sessionQueue, { () -> Void in
                
                session.startRunning()
                NSLog("Session started")
            });
            
            self.captureSession = session
            self.captureDevice = captureDevice
            self.addGestureRecognizer(self.focusTapGestureRecognizer)
        } catch let error as NSError {
            NSLog("Failed to start session: \(error.localizedDescription)")
        }
    }
    
    func stopSession() {
        guard let captureSession = self.captureSession else {
            NSLog("Session already stopped")
            return
        }
        self.removeGestureRecognizer(self.focusTapGestureRecognizer)
        self.captureSession = nil
        dispatch_async(self.sessionQueue) { () -> Void in
            captureSession.stopRunning()
        }
        NSLog("Session stopped")
    }
    
    
    private func drawBoxes(color:UIColor, features: [CIFeature],videoBox:CGRect,orientation:UIDeviceOrientation) {
        //        NSLog("Found %d faces",features.count)
        guard let captureLayer = self.captureLayer else {
            NSLog("No capture layer active")
            return;
        }
        
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        defer {
            CATransaction.commit()
        }
        
        var boxLayers : [CALayer] = []
        if let sublayers = captureLayer.sublayers {
            boxLayers.reserveCapacity(sublayers.count)
            for layer in sublayers {
                if layer.borderColor === color.CGColor {
                    layer.hidden = true
                    boxLayers.insert(layer,atIndex: 0)
                }
            }
        }
        
        if features.count == 0 {
            // no faces
            return;
        }
        
        let isMirrored = captureLayer.connection.videoMirrored
        let videoGravity = captureLayer.videoGravity
        let parentFrameSize = captureLayer.frame.size
        let previewBox = self.dynamicType.videoPreviewBoxForGravity(videoGravity, frameSize: parentFrameSize, apertureSize: videoBox.size)
        
        for feature in features {
            var faceRect = feature.bounds
            
            // flip preview width and height
            var temp = faceRect.size.width
            faceRect.size.width = faceRect.size.height
            faceRect.size.height = temp
            temp = faceRect.origin.x
            faceRect.origin.x = faceRect.origin.y
            faceRect.origin.y = temp
            
            // scale coordinates so they fit in the preview box, which may be scaled
            let widthScaleBy = previewBox.size.width / videoBox.size.height
            let heightScaleBy = previewBox.size.height / videoBox.size.width
            faceRect.size.width *= widthScaleBy
            faceRect.size.height *= heightScaleBy
            faceRect.origin.x *= widthScaleBy
            faceRect.origin.y *= heightScaleBy
            
            if isMirrored {
                faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y)
            } else {
                faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y)
            }
            
            // re-use existing layer if possible
            let featureLayer = boxLayers.popLast() ?? {
                let l = CALayer()
                l.borderColor = color.CGColor
                l.borderWidth = 2
                captureLayer.addSublayer(l)
                // no need to push in "faceLayers" since we're going to filter it from the capture layer's list of sublayers the next time this runs
                return l
                }()
            
            featureLayer.frame = faceRect
            
            switch(orientation) {
            case UIDeviceOrientation.Portrait:
                featureLayer.setAffineTransform(CGAffineTransformMakeRotation(RadiansFromDegrees(0)))
            case UIDeviceOrientation.PortraitUpsideDown:
                featureLayer.setAffineTransform(CGAffineTransformMakeRotation(RadiansFromDegrees(180)))
            case UIDeviceOrientation.LandscapeLeft:
                featureLayer.setAffineTransform(CGAffineTransformMakeRotation(RadiansFromDegrees(90)))
            case UIDeviceOrientation.LandscapeRight:
                featureLayer.setAffineTransform(CGAffineTransformMakeRotation(RadiansFromDegrees(-90)))
            case UIDeviceOrientation.FaceUp:
                fallthrough
            case UIDeviceOrientation.FaceDown:
                fallthrough
            default:
                break
                // leave the layer in its last known orientation
            }
            featureLayer.hidden = false
        }
    }
    
    
    class func videoPreviewBoxForGravity(gravity:String,frameSize:CGSize,apertureSize:CGSize) -> CGRect {
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        let size : CGSize
        switch gravity {
        case AVLayerVideoGravityResizeAspectFill:
            if viewRatio > apertureRatio {
                size = CGSize(
                    width: frameSize.width,
                    height: apertureSize.width * (frameSize.width / apertureSize.height))
            } else {
                size = CGSize(
                    width: apertureSize.height * (frameSize.height / apertureSize.width),
                    height: frameSize.height
                )
            }
        case AVLayerVideoGravityResizeAspect:
            if viewRatio > apertureRatio {
                size = CGSize(
                    width: apertureSize.height * (frameSize.height / apertureSize.width),
                    height: frameSize.height
                )
            } else {
                size = CGSize(
                    width: frameSize.width,
                    height: apertureSize.width * (frameSize.width / apertureSize.height)
                )
            }
        case AVLayerVideoGravityResize:
            size = frameSize
        default:
            size = CGSizeZero
        }
        
        var videoBox = CGRectZero
        videoBox.size = size
        
        if size.width < frameSize.width {
            videoBox.origin.x = (frameSize.width - size.width) / 2
        } else {
            videoBox.origin.x = (size.width - frameSize.width)  / 2
        }
        
        if size.height < frameSize.height {
            videoBox.origin.y = (frameSize.height - size.height) / 2
            videoBox.origin.y = (size.height - frameSize.height) / 2
        }
        
        return videoBox
    }

    // MARK: handlers
    func focusTap(sender : UITapGestureRecognizer) {
        if sender.state == .Ended {
            if let  captureDevice = self.captureDevice,
                captureLayer = self.captureLayer {
                let view = self
                let tapLocation = sender.locationInView(view)
                let viewBounds = view.bounds
                let devicePoint = captureLayer.captureDevicePointOfInterestForPoint(tapLocation)
                
                dispatch_async(self.sessionQueue, { () -> Void in
                    do {
                        try captureDevice.lockForConfiguration()
                        defer {
                            captureDevice.unlockForConfiguration()
                        }
                        let focusMode = AVCaptureFocusMode.AutoFocus
                        let exposureMode = AVCaptureExposureMode.AutoExpose
                        
                        var didChangeFocus = false
                        var didChangeExposure = false
                        if captureDevice.focusPointOfInterestSupported && captureDevice.isFocusModeSupported(focusMode) {
                            captureDevice.focusPointOfInterest = devicePoint
                            captureDevice.focusMode = focusMode
                            didChangeFocus = true
                        }
                        if captureDevice.exposurePointOfInterestSupported && captureDevice.isExposureModeSupported(exposureMode) {
                            captureDevice.exposurePointOfInterest = devicePoint
                            captureDevice.exposureMode = exposureMode
                            didChangeExposure = true
                        }
                        
                        NSLog("Focus changed: \(didChangeFocus) exposure changed: \(didChangeExposure)")
                    } catch let error as NSError {
                        NSLog("Cannot set focus point: %@",error.localizedDescription)
                    }
                })
            }
        }
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer,kCMAttachmentMode_ShouldPropagate)
        let image = CIImage(CVPixelBuffer: pixelBuffer!, options: attachments as? [String:AnyObject])
        let curDeviceOrientation = UIDevice.currentDevice().orientation
        
        /* kCGImagePropertyOrientation values
         The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
         by the TIFF and EXIF specifications -- see enumeration of integer constants.
         The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
         
         used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
         If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
        
        enum exif : Int32 {
            case PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1 //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
            case PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT		= 2 //   2  =  0th row is at the top, and 0th column is on the right.
            case PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3 //   3  =  0th row is at the bottom, and 0th column is on the right.
            case PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4 //   4  =  0th row is at the bottom, and 0th column is on the left.
            case PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5 //   5  =  0th row is on the left, and 0th column is the top.
            case PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6 //   6  =  0th row is on the right, and 0th column is the top.
            case PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7 //   7  =  0th row is on the right, and 0th column is the bottom.
            case PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
        }
        
        let exifOrientation : exif
        switch curDeviceOrientation {
        case UIDeviceOrientation.PortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = exif.PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM
        case UIDeviceOrientation.LandscapeLeft:    // Device oriented horizontally, home button on the right
            if(self.isUsingFrontFacingCamera) {
                exifOrientation = exif.PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT
            } else {
                exifOrientation = exif.PHOTOS_EXIF_0ROW_TOP_0COL_LEFT
            }
        case UIDeviceOrientation.LandscapeRight:    // Device oriented horizontally, home button on the left
            if(self.isUsingFrontFacingCamera) {
                exifOrientation = exif.PHOTOS_EXIF_0ROW_TOP_0COL_LEFT
            } else {
                exifOrientation = exif.PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT
            }
        case UIDeviceOrientation.Portrait:
            fallthrough
        default:
            exifOrientation = exif.PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP
        }
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        let clap = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
        let imageOptions = [ CIDetectorImageOrientation : NSNumber(int:exifOrientation.rawValue)]
        
//        let textFeatures = self.textDetector.featuresInImage(image, options: imageOptions)
//        dispatch_async(dispatch_get_main_queue()) { () -> Void in
//            self.drawBoxes(UIColor.greenColor(),features:textFeatures,videoBox:clap,orientation:curDeviceOrientation)
//        }

        var imageTransform : CGAffineTransform
        switch(curDeviceOrientation) {
        case UIDeviceOrientation.FaceUp:
            fallthrough
        case UIDeviceOrientation.Portrait:
            fallthrough
        case UIDeviceOrientation.FaceDown:
            imageTransform = CGAffineTransformMakeRotation(RadiansFromDegrees(-90))
        case UIDeviceOrientation.PortraitUpsideDown:
            imageTransform = CGAffineTransformMakeRotation(RadiansFromDegrees(-270))
        case UIDeviceOrientation.LandscapeRight:
            imageTransform = CGAffineTransformMakeRotation(RadiansFromDegrees(-180))
        case UIDeviceOrientation.LandscapeLeft:
            fallthrough
        default:
            imageTransform = CGAffineTransformIdentity
            break
            // leave the layer in its last known orientation
        }

        let rotatedImage = image.imageByApplyingTransform(imageTransform)
        
        let blackAndWhiteFilter = CIFilter(name: "CIColorControls")!
        blackAndWhiteFilter.setValue(NSNumber(float: 0), forKey: "inputBrightness")
        blackAndWhiteFilter.setValue(NSNumber(float: 1.1), forKey: "inputContrast")
        blackAndWhiteFilter.setValue(NSNumber(float: 0), forKey: "inputSaturation")
        blackAndWhiteFilter.setValue(rotatedImage, forKey: kCIInputImageKey)
        
        let exposureAdjustFilter = CIFilter(name: "CIExposureAdjust")!
        exposureAdjustFilter.setValue(blackAndWhiteFilter.outputImage, forKey: kCIInputImageKey)
        exposureAdjustFilter.setValue(NSNumber(float: 0.7), forKey: "inputEV")

        
        if let filteredImage = exposureAdjustFilter.outputImage {
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(filteredImage, fromRect: filteredImage.extent)
            let candidateImage = UIImage(CGImage: cgImage)
            tesseract.image = candidateImage
            tesseract.recognize()
            let recognizedText = tesseract.recognizedText
            if !recognizedText.isEmpty {
                NSLog("Recognized text: %@",recognizedText)
            }
        }
    }
}

private func RadiansFromDegrees(degrees : CGFloat) -> CGFloat {
    return degrees * CGFloat(M_PI / 180)
}

