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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var ball = SCNNode()
    var plane = SCNNode()
    var plane2 = SCNNode()
    var pillar = SCNNode()
    
    var cameraLoc: float4!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/InitialScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        
        let wait:SCNAction = SCNAction.wait(duration: 2)
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
            } else if (node.name == "pillar") {
                
                pillar = node
                let pillarShape:SCNPhysicsShape = SCNPhysicsShape(geometry: pillar.geometry!, options: nil)
                pillar.physicsBody = SCNPhysicsBody(type: .dynamic, shape: pillarShape)
                pillar.physicsBody?.mass = 10
                pillar.physicsBody?.restitution = 1
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    

    func launchBall() {
        let x = cameraLoc.x
        let y = cameraLoc.y
        let z = cameraLoc.z
        let ballx = ball.position.x
        let bally = ball.position.y
        let ballz = ball.position.z
        ball.physicsBody?.applyForce(SCNVector3Make(ballx-x, bally-y, ballz-z), asImpulse: true)
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("Updating")
        cameraLoc = frame.camera.transform.columns.3
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
