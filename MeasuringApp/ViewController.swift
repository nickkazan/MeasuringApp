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

//This extension enables me to add a line once both points are created
extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}

//This extension is the distance equation for 3 points
extension SCNVector3 {
    static func calculateDistance(from vector1: SCNVector3, to vector2: SCNVector3) -> Float {
        let x0 = vector1.x;
        let x1 = vector2.x;
        let y0 = vector1.y;
        let y1 = vector2.y;
        let z0 = vector1.z;
        let z1 = vector2.z;
        
        return (39.3701 * (sqrtf( powf((x1 - x0),2) + powf((y1 - y0),2) + powf((z1 - z0), 2) )));
    }
}


class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    var numberOfTaps: Int = 0;
    var startPoint: SCNVector3!
    var endPoint: SCNVector3!

    override func viewDidLoad() {
        super.viewDidLoad()
        //Add Feature Points when scanning the environment
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints];
        sceneView.delegate = self
        //Add proper lighting to objects
        sceneView.autoenablesDefaultLighting = true;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        // Create a session configuration and add horizontal/vertical plane detection
        let configuration = ARWorldTrackingConfiguration();
        configuration.planeDetection = [.horizontal, .vertical];

        // Run the view's session based on our configuration
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
    
    //This function runs when the user touches the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Focus on just the first touch and get it's location
        if let touch = touches.first{
            let touchLocation = touch.location(in: sceneView);
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            //Stop when we already have two points on screen
            if numberOfTaps <= 1 {
                if let hitResult = results.first{
                    //Set the start point if this happens to be the first touch from the user within the plane detected
                    if numberOfTaps == 0{
                        startPoint = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z);
                    }
                    //Set the end point if this happens to be the second touch from the user within the plane detected
                    if numberOfTaps == 1{
                        endPoint = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z);
                        //Since the second point has been placed, add the line in between the two
                        let line = SCNGeometry.line(from: startPoint, to: endPoint);
                        line.firstMaterial?.diffuse.contents = UIColor.red;
                        let lineNode = SCNNode(geometry: line);
                        lineNode.position = SCNVector3Zero;
                        sceneView.scene.rootNode.addChildNode(lineNode);
                        //Use our calculation extension to find the distance between points
                        let distance = SCNVector3.calculateDistance(from: startPoint, to: endPoint);
                        print(distance);
                        makeTextAppear(distance: distance, location: endPoint);
                    }
                    //This is where we actually create the physical point that associates to the startPoint and endPoint
                    let sphere: SCNSphere;
                    sphere = SCNSphere(radius: 0.003);
                    sphere.firstMaterial?.diffuse.contents = UIColor.red;
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
    
    func makeTextAppear(distance: Float, location: SCNVector3){
        //Create the text to display the distance and set its position
        let text = SCNText(string: String(format: "%.1f\"", distance), extrusionDepth: 2);
        text.font = UIFont.systemFont(ofSize: 10);
        text.firstMaterial?.diffuse.contents = UIColor.red;
        
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3Make(location.x, location.y, location.z);
        textNode.scale = SCNVector3Make(0.005, 0.005, 0.005)
        sceneView.scene.rootNode.addChildNode(textNode)
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
    
    //This function renders in the plane and adds a grid material to show the user locations that are identified as a plane
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
