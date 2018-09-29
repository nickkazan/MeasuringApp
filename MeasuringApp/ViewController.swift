//
//  ViewController.swift
//  MeasuringApp
//
//  Created by Nick Kazan on 2018-09-26.
//  Copyright © 2018 Nick Kazan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var numberOfTaps = 0;
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints];
//        // Set the view's delegate
        sceneView.delegate = self
//        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//
//        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//
//        // Set the scene to the view
//        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration();
        configuration.planeDetection = [.horizontal, .vertical];

        // Run the view's session
        sceneView.session.run(configuration);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var startPoint: SCNVector3!
        var endPoint: SCNVector3!
        if let touch = touches.first{
            let touchLocation = touch.location(in: sceneView);
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if numberOfTaps <= 1 {
                if let hitResult = results.first{
                    if numberOfTaps == 0{
                        startPoint = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z);
                    }
                    if numberOfTaps == 1{
                        endPoint = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z);
                        
                    }
                    let sphere: SCNSphere;
                    sphere = SCNSphere(radius: 0.003);
                    let node = SCNNode();
                    node.position = SCNVector3(x: hitResult.worldTransform.columns.3.x, y: hitResult.worldTransform.columns.3.y + node.boundingSphere.radius, z: hitResult.worldTransform.columns.3.z);
                    node.geometry = sphere;
                    sceneView.scene.rootNode.addChildNode(node);
                    numberOfTaps += 1;
                }
            }
            else{
                return;
            }
        }
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor{
            let planeAnchor = anchor as! ARPlaneAnchor;
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z));
            let planeNode = SCNNode();
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z);
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0);
            
            let gridMaterial = SCNMaterial();
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png");
            plane.materials = [gridMaterial];
            planeNode.geometry = plane;
            
            node.addChildNode(planeNode);
        }
        else{
            return;
        }
    }
}