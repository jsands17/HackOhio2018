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
    @IBOutlet weak var togglePillarButton: UIButton!
    
    var ball = SCNNode()
    var pillarDrop: Bool! = true
    var placeBall: Bool! = true
    var ballDistanceFromCamera: Float = 1
    
    var cameraLoc: float4!
    var detectedPlanes: [String : SCNNode] = [:]
    var pillars: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.session.delegate = self
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        
        let wait:SCNAction = SCNAction.wait(duration: 2)
        let runAfter:SCNAction = SCNAction.run { _ in
            self.addSceneContent()
        }
        
        let seq:SCNAction = SCNAction.sequence([wait, runAfter])
        sceneView.scene.rootNode.runAction(seq)
        
        self.sceneView.debugOptions =
            SCNDebugOptions(rawValue: ARSCNDebugOptions.showWorldOrigin.rawValue |
                ARSCNDebugOptions.showFeaturePoints.rawValue)
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if pillarDrop {
            dropPillar(sender: sender)
        } else {
            dropBall(sender: sender)
        }
    }
    
    func dropBall(sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: sceneView)
        
        if placeBall {
            let cameraDir:SCNVector3 = getUserVector().0
            let cameraPos:SCNVector3 = getUserVector().1
            
            ball.removeFromParentNode()
            let newBall = SCNNode()
            ball = newBall
            ball.geometry = SCNSphere(radius: 0.1)
            ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
            ball.physicsBody?.isAffectedByGravity = false
            ball.physicsBody?.restitution = 1
            ball.position = SCNVector3Make(0, 0, -0.5)
            sceneView.pointOfView?.addChildNode(ball)
            placeBall = !placeBall

            ball.position = SCNVector3Make(cameraPos.x + (cameraDir.x * ballDistanceFromCamera), cameraPos.y + (cameraDir.y * ballDistanceFromCamera), cameraPos.z + (cameraDir.z * ballDistanceFromCamera))
            sceneView.scene.rootNode.addChildNode(ball)
        } else {
            let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
            if !hitTestResult.isEmpty {
                for hitResult in hitTestResult {
                    if (hitResult.node == ball) {
                        ball.physicsBody?.isAffectedByGravity = true
                        launchBall()
                    }
                }
            }
        }
        
    }
    
    func dropPillar(sender: UITapGestureRecognizer) {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        let location = sender.location(in: sceneView)
        addPillar(location: location)
    }
    
    func addSceneContent() {
        let initialNode = sceneView.scene.rootNode.childNode(withName: "rootNode", recursively: false)
        initialNode?.position = SCNVector3(0, -1, 0)
        self.sceneView.scene.rootNode.enumerateChildNodes{ (node, _) in
            
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
        let cameraDir:SCNVector3 = getUserVector().0

        ball.physicsBody?.applyForce(SCNVector3Make(cameraDir.x * 10, cameraDir.y * 10, cameraDir.z * 10), asImpulse: true)
        ball.runAction(SCNAction.sequence([
            SCNAction.wait(duration: 5.0),
            SCNAction.removeFromParentNode()
            ])
        )
        placeBall = !placeBall
    }
    
    func addPillar(location: CGPoint) {
        guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
        let currentPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
                                             hitTestResult.worldTransform.columns.3.y,
                                             hitTestResult.worldTransform.columns.3.z)
        
        let pillarGeometry = SCNCylinder(radius: 0.1, height: 0.5)
        pillarGeometry.firstMaterial?.diffuse.contents = UIColor.green
        let pillarNode = SCNNode(geometry: pillarGeometry)
        pillarNode.position = SCNVector3Make(currentPosition.x,
                                             currentPosition.y + (Float(pillarGeometry.height) / 2),
                                             currentPosition.z)
        
        pillarNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        pillarNode.physicsBody?.mass = 2.0
        pillarNode.physicsBody?.friction = 0.8
        pillarNode.runAction(SCNAction.customAction(duration: 0.5, action: { (node, elapsedTime) -> () in
            if(node.position.y < -2) {
                node.removeFromParentNode()
            }
            print("Pillar is alive.")
        }))
        sceneView.scene.rootNode.addChildNode(pillarNode)
        pillars.append(pillarNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        planeNode.opacity = 0.3
        planeNode.rotation = SCNVector4Make(1, 0, 0, -Float.pi / 2.0)
        
        
        let box = SCNBox(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z), length: 0.001, chamferRadius: 0)
        
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        
        node.addChildNode(planeNode)
        detectedPlanes[planeAnchor.identifier.uuidString] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
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
    
    @IBAction func togglePillarDrop(_ sender: Any) {
        togglePillarButton.setTitle(pillarDrop ? "Add Pillar" : "Add Ball", for: .normal)
        pillarDrop = !pillarDrop
        
        //print("x: ", cameraDirAndPos.0.x, "  y: ", cameraDirAndPos.0.y, "  z: ", cameraDirAndPos.0.z)
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
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
