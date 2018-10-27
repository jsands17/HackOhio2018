//
//  ViewController.swift
//  HackOhio2018
//
//  Created by Jeremy Sandrof on 10/27/18.
//  Copyright © 2018 Jeremy Sandrof. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
//    var ball = SCNNode()
//    var pillar = SCNNode()
//    var plane = SCNNode()
//    var plane2 = SCNNode()
    
    var detectedPlanes: [String : SCNNode] = [:]
    var pillars: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/InitialScene.scn")!
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        
        self.sceneView.debugOptions =
            SCNDebugOptions(rawValue: ARSCNDebugOptions.showWorldOrigin.rawValue |
                ARSCNDebugOptions.showFeaturePoints.rawValue)

        
//        let wait:SCNAction = SCNAction.wait(duration: 3)
//        let runAfter:SCNAction = SCNAction.run { _ in
//            self.addSceneContent()
//        }
//
//        let seq:SCNAction = SCNAction.sequence([wait, runAfter])
//        sceneView.scene.rootNode.runAction(seq)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    /*@objc func handleTap(sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
        if !hitTestResult.isEmpty {
            for hitResult in hitTestResult {
                if (hitResult.node == ball) {
                    launchBall()
                }
            }
        }
    }*/
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        let location = sender.location(in: sceneView)
        addPillar(location: location)
    }
    
    /*func addSceneContent() {
        let initialNode = sceneView.scene.rootNode.childNode(withName: "rootNode", recursively: false)
        initialNode?.position = SCNVector3(0, -1, 0)
        
        self.sceneView.scene.rootNode.enumerateChildNodes{ (node, _) in
            
            if (node.name == "movingSphere") {
                
                ball = node
                ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
                ball.physicsBody?.isAffectedByGravity = true
                ball.physicsBody?.restitution = 1
                
                
            } else if (node.name == "stillPlane") {
                
                plane = node
                let boxShape:SCNPhysicsShape = SCNPhysicsShape(geometry: plane.geometry!, options: nil)
                plane.physicsBody = SCNPhysicsBody(type: .static, shape: boxShape)
                plane.physicsBody?.restitution = 1
            } else if (node.name == "plane2") {
                
                plane2 = node
                let boxShape:SCNPhysicsShape = SCNPhysicsShape(geometry: plane2.geometry!, options: nil)
                plane2.physicsBody = SCNPhysicsBody(type: .static, shape: boxShape)
                plane2.physicsBody?.restitution = 1
            }
        }
    }*/
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    

    /*func launchBall() {
        ball.physicsBody?.applyForce(SCNVector3Make(0, 0, -3), asImpulse: true)
    }*/
    
    func addPillar(location: CGPoint) {
        guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
        let currentPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
                                             hitTestResult.worldTransform.columns.3.y,
                                             hitTestResult.worldTransform.columns.3.z)
        // 3
        let pillarGeometry = SCNCylinder(radius: 0.1, height: 0.5)
        pillarGeometry.firstMaterial?.diffuse.contents = UIColor.green
        let pillarNode = SCNNode(geometry: pillarGeometry)
        pillarNode.position = SCNVector3Make(currentPosition.x,
                                             currentPosition.y + (Float(pillarGeometry.height) / 2),
                                             currentPosition.z)
        
        pillarNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        pillarNode.physicsBody?.mass = 2.0
        pillarNode.physicsBody?.friction = 0.8
        
        sceneView.scene.rootNode.addChildNode(pillarNode)
        // 4
        pillars.append(pillarNode)
    }
    
    // MARK: - ARSCNViewDelegate
    

    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // 2
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        // 3
        planeNode.opacity = 0.3
        // 4
        planeNode.rotation = SCNVector4Make(1, 0, 0, -Float.pi / 2.0)
        

        let box = SCNBox(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z), length: 0.001, chamferRadius: 0)
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        
        node.addChildNode(planeNode)
        // 5
        detectedPlanes[planeAnchor.identifier.uuidString] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // 2
        guard let planeNode = detectedPlanes[planeAnchor.identifier.uuidString] else { return }
        let planeGeometry = planeNode.geometry as! SCNPlane
        planeGeometry.width = CGFloat(planeAnchor.extent.x)
        planeGeometry.height = CGFloat(planeAnchor.extent.z)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        
        let box = SCNBox(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z), length: 0.001, chamferRadius: 0)
        planeNode.physicsBody?.physicsShape = SCNPhysicsShape(geometry: box, options: nil)
    }

    
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
