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
    @IBOutlet weak var sphereButton: UIButton!
    @IBOutlet weak var coneButton: UIButton!
    
    var objectSelector = 0
    var ball = SCNNode()
    var placeBall: Bool! = true
    var ballDistanceFromCamera: Float = 1
    var ballImpulse: Float = 100
    
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
        sceneView.autoenablesDefaultLighting = true
        
        let wait:SCNAction = SCNAction.wait(duration: 2)
        let runAfter:SCNAction = SCNAction.run { _ in
            self.addSceneContent()
        }
        
        let seq:SCNAction = SCNAction.sequence([wait, runAfter])
        sceneView.scene.rootNode.runAction(seq)
        
//        self.sceneView.debugOptions =
//            SCNDebugOptions(rawValue: ARSCNDebugOptions.showWorldOrigin.rawValue |
//                ARSCNDebugOptions.showFeaturePoints.rawValue)
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        switch objectSelector {
        case 0:
            dropPillar(sender: sender)
            break
        case 1:
            dropBall(sender: sender)
            break
        case 2:
            dropCone(sender: sender)
            break
        default:
            dropBall(sender: sender)
        }
    }
    
    /*/////////////////////////////////////////////////////
     Pillar Functions
     **///////////////////////////////////////////////////
    @IBAction func selectPillars(_ sender: Any) {
        objectSelector = 0
        coneButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
        togglePillarButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.2)
        sphereButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    func dropPillar(sender: UITapGestureRecognizer) {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        let location = sender.location(in: sceneView)
        addPillar(location: location)
    }
    
    func addPillar(location: CGPoint) {
        guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
        let currentPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
                                             hitTestResult.worldTransform.columns.3.y,
                                             hitTestResult.worldTransform.columns.3.z)
        
        let coneGeometry = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 1.5)
        coneGeometry.firstMaterial?.diffuse.contents = UIColor.red
        let coneNode = SCNNode(geometry: coneGeometry)
        coneNode.position = SCNVector3Make(currentPosition.x,
                                             currentPosition.y + (Float(coneGeometry.height) / 2),
                                             currentPosition.z)
        
        coneNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        coneNode.physicsBody?.mass = 2.0
        coneNode.physicsBody?.friction = 0.8
        coneNode.runAction(SCNAction.customAction(duration: 0.5, action: { (node, elapsedTime) -> () in
            if(node.position.y < -2) {
                node.removeFromParentNode()
            }
            print("Pillar is alive.")
        }))
        sceneView.scene.rootNode.addChildNode(coneNode)
        pillars.append(coneNode)
    }
    
    /*/////////////////////////////////////////////////////
     Ball Functions
     **///////////////////////////////////////////////////
    @IBAction func selectBalls(_ sender: Any) {
        objectSelector = 1
        coneButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
        togglePillarButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
        sphereButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.2)
    }
    
    func dropBall(sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(in: sceneView)
        
        if placeBall {
            let cameraDir:SCNVector3 = getUserVector().0
            let cameraPos:SCNVector3 = getUserVector().1
            
            let newBall = SCNNode()
            ball = newBall
            ball.geometry = SCNSphere(radius: 0.1)
            ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
            ball.physicsBody?.isAffectedByGravity = false
            ball.physicsBody?.restitution = 1
            ball.physicsBody?.mass = 5
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
    
    func launchBall() {
        let cameraDir:SCNVector3 = getUserVector().0
        ball.physicsBody?.applyForce(SCNVector3Make(cameraDir.x * ballImpulse, cameraDir.y * ballImpulse, cameraDir.z * ballImpulse), asImpulse: true)
        
        ball.runAction(SCNAction.sequence([
            SCNAction.wait(duration: 5.0),
            SCNAction.removeFromParentNode()
            ])
        )
        placeBall = !placeBall
    }
    
    @IBAction func selectCone(_ sender: Any) {
        objectSelector = 2
        coneButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.2)
        togglePillarButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
        sphereButton.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    func dropCone(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
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
    
    
    /*/////////////////////////////////////////////////////
     Load Scene and Renderer Functions
     **///////////////////////////////////////////////////
    
    func addSceneContent() {
        let initialNode = sceneView.scene.rootNode.childNode(withName: "rootNode", recursively: false)
        initialNode?.position = SCNVector3(0, -1, 0)
        self.sceneView.scene.rootNode.enumerateChildNodes{ (node, _) in
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        planeNode.opacity = 0.0
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
//        planeGeometry.width = CGFloat(planeAnchor.extent.x)
//        planeGeometry.height = CGFloat(planeAnchor.extent.z)
        planeGeometry.width = 100
        planeGeometry.height = 100
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        
        //let box = SCNBox(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z), length: 0.001, chamferRadius: 0)
        let box = SCNBox(width: 100, height: 100, length: 0.001, chamferRadius: 0)
        
        planeNode.physicsBody?.physicsShape = SCNPhysicsShape(geometry: box, options: nil)
    }
    
    /*/////////////////////////////////////////////////////
     Helper Functions
     **///////////////////////////////////////////////////
    
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    /*/////////////////////////////////////////////////////
     View Functions
     **///////////////////////////////////////////////////
    
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
    
    /*/////////////////////////////////////////////////////
     Session Functions
     **///////////////////////////////////////////////////
    
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
