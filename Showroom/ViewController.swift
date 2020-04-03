//
//  ViewController.swift
//  Showroom
//
//  Created by Talha Rehman on 3/29/20.
//  Copyright © 2020 Scan2cart. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    private var node: SCNNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target:self,action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        sceneView.addGestureRecognizer(rotateGesture)
        // Set the scene to the view
//        sceneView.scene = scene
    }
    
    @objc
       func didTap(_ gesture: UITapGestureRecognizer) {
           let sceneViewTappedOn = gesture.view as! ARSCNView
           let touchCoordinates = gesture.location(in: sceneViewTappedOn)
           let hitTest = sceneViewTappedOn.hitTest(touchCoordinates, types: .existingPlaneUsingExtent)
      

           guard !hitTest.isEmpty, let hitTestResult = hitTest.first else {
               return
           }
           
           let position = SCNVector3(hitTestResult.worldTransform.columns.3.x,
                                     hitTestResult.worldTransform.columns.3.y,
                                     hitTestResult.worldTransform.columns.3.z)
           
            
            addItemToPosition(position)

        
//           print(position)
          
        
       }
    
    private func addPinchGesture() {
          let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
          self.sceneView.addGestureRecognizer(pinchGesture)
      }
    
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        
//        print("Ready to scale!")

    
           switch gesture.state {
           // 1
           case .began:
               gesture.scale = CGFloat(node.scale.x)
           // 2
           case .changed:
               var newScale: SCNVector3
       // a
               if gesture.scale < 0.5 {
                   newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
       // b
               } else if gesture.scale > 3 {
                   newScale = SCNVector3(3, 3, 3)
       // c
               } else {
                   newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
               }
       // d
               node.scale = newScale
           default:
               break
           }
       }
    
    private func addRotationGesture() {
           let panGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
           self.sceneView.addGestureRecognizer(panGesture)
       }
    
    private var lastRotation: Float = 0
    
       @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
        
//        print("Ready to rotate!")
        
           switch gesture.state {
           case .changed:
               // 1
               self.node.eulerAngles.y = self.lastRotation + Float(gesture.rotation)
           case .ended:
               // 2
               self.lastRotation += Float(gesture.rotation)
           default:
               break
           }
       }
    
    
 func addItemToPosition(_ position: SCNVector3) {
    
       guard let url = Bundle.main.url(forResource: "chair",
                                       withExtension: "usdz",
                                       subdirectory: "art.scnassets") else { return }
       
       let scene = try! SCNScene(url: url, options: [.checkConsistency: true])
       DispatchQueue.main.async {
         
        if let node = scene.rootNode.childNode(withName: "chair", recursively: false) {
            
            guard let xnode = self.node else{
                node.position = position
                self.node = node
                self.sceneView.scene.rootNode.addChildNode(node)
                
                return
            }
            xnode.position = SCNVector3Make(position.x, position.y, position.z)
            self.sceneView.scene.rootNode.addChildNode(self.node)

            
           }
       }
   }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
      
        if let planeAnchor = anchor as? ARPlaneAnchor {
           
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0)

            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.x, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane {
            plane.width = CGFloat(planeAnchor.extent.x)
            plane.height = CGFloat(planeAnchor.extent.z)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
