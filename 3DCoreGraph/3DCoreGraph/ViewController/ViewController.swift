//
//  ViewController.swift
//  3DCoreGraph
//
//  Created by Yehezkiel Salvator Christanto on 05/07/24.
//

import UIKit
import SceneKit
import ARKit
import SwiftUI




class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var CAcoordinates = [SCNVector3]()
    var TWcoordinates = [SCNVector3]()
    var button = UIButton(type:.system)
    var node3D: SCNNode = SCNNode()
    var buttonName: KeypointsType = .TW
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        
        fetchDataTW() { [weak self] in
            self?.fetchDataCA()
            let geometry3D = self?.createGeometry(coordinates: self!.TWcoordinates)
            self?.node3D = SCNNode(geometry: geometry3D)
            self?.sceneView.scene.rootNode.addChildNode(self!.node3D)
        }
        
        //create Button
        button.setTitle("Switch to CA", for: .normal)
        button.frame = CGRect(x: 20, y: 50, width: 100, height: 50)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        
        
        
        self.view.addSubview(button)
        scene.rootNode.addChildNode(self.node3D)
    }
    
    @objc func buttonPressed() {
        node3D.removeFromParentNode()
        if buttonName == .TW {
            buttonName = .CA
            print("berapa CA: \(CAcoordinates.count)")
            let geometry3D = createGeometry(coordinates: CAcoordinates)
            node3D = SCNNode(geometry: geometry3D)
            sceneView.scene.rootNode.addChildNode(self.node3D)
            button.setTitle("Switch to TW", for: .normal)
        } else {
            buttonName = .TW
            let geometry3D = self.createGeometry(coordinates: TWcoordinates)
            node3D = SCNNode(geometry: geometry3D)
            sceneView.scene.rootNode.addChildNode(self.node3D)
            button.setTitle("Switch to CA", for: .normal)
        }
        
        
    }
    
    func fetchDataCA() {
        guard let url = Bundle.main.url(forResource: "CA_Keypoints", withExtension: "json") else {
            print("json file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("data: \(data)")
            let coordinates = try JSONDecoder().decode([Coordinates].self, from: data)
            DispatchQueue.main.async { [weak self] in
                for coordinate in coordinates {
                    self?.CAcoordinates.append(
                        SCNVector3(
                            x: Float(coordinate.keypoints[0]),
                            y: Float(coordinate.keypoints[1]),
                            z: Float(coordinate.keypoints[2])
                        )
                    )
                }
                
            }
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
    
    func fetchDataTW(completion: @escaping () -> Void) {
        guard let url = Bundle.main.url(forResource: "TW_Keypoints", withExtension: "json") else {
            print("json file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("data: \(data)")
            let coordinates = try JSONDecoder().decode([Coordinates].self, from: data)
            DispatchQueue.main.async { [weak self] in
                for coordinate in coordinates {
                    self?.TWcoordinates.append(
                        SCNVector3(
                            x: Float(coordinate.keypoints[0]),
                            y: Float(coordinate.keypoints[1]),
                            z: Float(coordinate.keypoints[2])
                        )
                    )
                }
                completion()
            }
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
    
    func normalizingCoordinates(coordinates: [SCNVector3], size: SCNVector3) -> [SCNVector3] {
        
        // Determine the bounding box of the keypoints
        let minX = coordinates.map { $0.x }.min() ?? 0
        let minY = coordinates.map { $0.y }.min() ?? 0
        let minZ = coordinates.map { $0.z }.min() ?? 0
        let maxX = coordinates.map { $0.x }.max() ?? 0
        let maxY = coordinates.map { $0.y }.min() ?? 0
        let maxZ = coordinates.map { $0.z }.max() ?? 0
        
        let boundingBoxWidth = maxX - minX
        let boundingBoxHeight = maxY - minY
        let boundingBoxDepth = maxZ - minZ
        
        // Determine the scaling factors
        let scaleX = size.x / boundingBoxWidth
        let scaleY = size.y / boundingBoxHeight
        let scaleZ = size.z / boundingBoxDepth
        let scale = min(scaleX, scaleY, scaleZ)
        
        // Apply scaling and translation
        let offsetX = (size.x - boundingBoxWidth * scale) / 5 - minX * scale
        let offsetY = (size.y - boundingBoxHeight * scale) / 5 - minY * scale
        let offsetZ = (size.z - boundingBoxDepth * scale) / 5 - minZ * scale
        return coordinates.map { coordinate in
            let normalizedX = coordinate.x * scale + offsetX
            let normalizedY = coordinate.y * scale + offsetY
            let normalizedZ = coordinate.z * scale + offsetZ
            return SCNVector3(normalizedX, normalizedY, normalizedZ)
        }
    }
    
    func createGeometry(coordinates: [SCNVector3]) -> SCNGeometry {
        let normalizedCoordinates = normalizingCoordinates(coordinates: coordinates, size: SCNVector3(50, 50, 100))
        var indices: [Int32] = []
        for i in 0..<normalizedCoordinates.count - 1 {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        print(indices)
        let geometryElement = SCNGeometryElement(indices: indices,
                                                 primitiveType: .line)
        
        let geometry = SCNGeometry(sources: [SCNGeometrySource(vertices: normalizedCoordinates)], elements: [geometryElement])
        
        let material = SCNMaterial()
        material.emission.contents = UIColor.red
        material.emission.intensity = 1
        geometry.materials = [material]
        
        return geometry
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
