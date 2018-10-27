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
    
    var ball = SCNNode()
    var pillar = SCNNode()
    var plane = SCNNode()
    var plane2 = SCNNode()
    
    var planeGeometry:SCNPlane!
    var anchors = [ARAnchor]()
    var sceneLight:SCNLight!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/InitialScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        self.sceneView.debugOptions =
            SCNDebugOptions(rawValue: ARSCNDebugOptions.showWorldOrigin.rawValue |
                ARSCNDebugOptions.showFeaturePoints.rawValue)

        
        let wait:SCNAction = SCNAction.wait(duration: 3)
        let runAfter:SCNAction = SCNAction.run { _ in
            self.addSceneContent()
        }
        
        let seq:SCNAction = SCNAction.sequence([wait, runAfter])
        sceneView.scene.rootNode.runAction(seq)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
        if !hitTestResult.isEmpty {
            for hitResult in hitTestResult {
                if (hitResult.node == ball) {
                    launchBall()
                }
            }
        }
    }
    
    func addSceneContent() {
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
    }
    
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
    
    

    func launchBall() {
        ball.physicsBody?.applyForce(SCNVector3Make(0, 0, -3), asImpulse: true)
    }
    
    func addPillar(locationAnchor: ARPlaneAnchor) {
        pillar.geometry = SCNCylinder(radius: 0.09, height: 1)
        pillar.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        
        pillar.position = SCNVector3(locationAnchor.center.x, 0, locationAnchor.center.z)
        
        sceneView.scene.rootNode.addChildNode(pillar)
    }
    
    // MARK: - ARSCNViewDelegate
    

    //Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node:SCNNode?
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
            planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            planeGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y:0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
            //updateMaterial()
            addPillar(locationAnchor: planeAnchor)
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
        }
        
        return node
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
                    
                    if let plane = planeNode.geometry as? SCNPlane {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.height = CGFloat(planeAnchor.extent.z)
                        
                        //updateMaterial()
                    }
                }
            }
        }
    }
    
    func updateMaterial() {
        let material = self.planeGeometry.materials.first!
        
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(self.planeGeometry.width), Float(self.planeGeometry.height), 1)
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
