//
//  BarcodeDetectionScene.swift
//  JogoDaMemoria
//
//  Created by Ian Manor on 12/09/17.
//  Copyright © 2017 ian. All rights reserved.
//

import UIKit
import SpriteKit
import Vision
import ARKit

class BarcodeDetectionScene: SKScene {
    // Create a barcode detection-request
    var lastTime: TimeInterval?
    
    override func update(_ currentTime: TimeInterval) {
        if lastTime != nil {
            if currentTime - lastTime! > 1 {
                scanBarcode()
                lastTime = currentTime
            }
        } else {
            lastTime = currentTime
        }
    }
    
    func scanBarcode() {
        print("check!")
        
        // Create an image handler and use the CGImage your UIImage instance
        // FIXME: I did not find any docs on how to configure the options properly so far.
        guard let sceneView = self.view as? ARSKView else {
            return
        }
        
        // Create anchor using the camera's current position
        if let currentFrame = sceneView.session.currentFrame {
            DispatchQueue.global(qos: .background).async {
                do {
                    let barcodeRequest = VNDetectBarcodesRequest(completionHandler: {(request, error) in
                        
                        // Loop through the found results
                        for result in request.results! {
                            
                            // Cast the result to a barcode-observation
                            if let barcode = result as? VNBarcodeObservation {
                                
                                if let payload = barcode.payloadStringValue {
                                    print("Payload: \(payload)")
                                }
                                
                                let hitObjects = sceneView.hitTest(barcode.topLeft, types: ARHitTestResult.ResultType.featurePoint)
                                if let firstHitDistance = hitObjects.last?.distance {
                                    print(firstHitDistance)
                                    var translation = matrix_identity_float4x4
                                    translation.columns.3.z = Float(firstHitDistance) * -1
                                    let transform = simd_mul(currentFrame.camera.transform, translation)
                                    
                                    print("has first hit!")
                                    let anchor = ARAnchor(transform: transform)
                                    sceneView.session.add(anchor: anchor)
                                }
                                
                                // Print barcode-values
                                print("Symbology: \(barcode.symbology.rawValue)")
                                
                                if let desc = barcode.barcodeDescriptor as? CIQRCodeDescriptor {
                                    let content = String(data: desc.errorCorrectedPayload, encoding: .utf8)
                                    
                                    // FIXME: This currently returns nil. I did not find any docs on how to encode the data properly so far.
                                    print("Payload: \(String(describing: content))")
                                    print("Error-Correction-Level: \(desc.errorCorrectionLevel)")
                                    print("Symbol-Version: \(desc.symbolVersion)")
                                }
                            }
                        }
                    })
                    
                    let handler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage, options: [.properties : ""])
                    try handler.perform([barcodeRequest])
                } catch {}
            }
        }
    }
}
