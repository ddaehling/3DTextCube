//
//  SceneKitObjectRepresentable.swift
//  SceneKitTest_delete
//
//  Created by Daniel Dähling on 04.08.20.
//

import SwiftUI
import SceneKit

struct SceneKitObjectRepresentable: UIViewRepresentable {
    
    @State var rotationValue : CGFloat = 0
    @State var rotationAxis : SCNVector3 = .init(x: 0, y: 0, z: 0)
    
    let cubeElements : [String] = ["1", "2", "3", "4", "5", "6"]
    
    
    func makeUIView(context: UIViewRepresentableContext<SceneKitObjectRepresentable>) -> SCNView {
        let sceneView = SCNView()
        sceneView.frame = .zero
        
        let scene = SCNScene()
        
        let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.2)
        box.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.3)
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "Box"
        
        for (index, element) in cubeElements.enumerated() {
            let text = SCNText(string: "Test\(element)", extrusionDepth: 0.01)
            text.firstMaterial?.diffuse.contents = UIColor.black
            text.font = UIFont(name: "system", size: 16)
            text.flatness = 0.1
            
            let textNode = SCNNode(geometry: text)
            
            let (minVec, maxVec) = textNode.boundingBox
            let pivotOffsetX = minVec.x + (maxVec.x - minVec.x) / 2
            let pivotOffsetY = minVec.y + (maxVec.y - minVec.y) / 2
            textNode.simdPivot = simd_float4x4([
                simd_float4.init(x: 20, y: 0, z: 0, w: 0),
                simd_float4.init(x: 0, y: 20, z: 0, w: 0),
                simd_float4.init(x: 0, y: 0, z: 20, w: 0),
                simd_float4.init(x: pivotOffsetX, y: pivotOffsetY, z: 0, w: 1)
            ])

            // Create a reliable source for hit testing:
            let plane = SCNBox(width: 1.8, height: 1.8, length: 0.01, chamferRadius: 0)
            plane.firstMaterial?.diffuse.contents = UIColor.clear
            let planeNode = CubeNode(id: index, geometry: plane)
//            planeNode.transform = SCNMatrix4MakeTranslation(minVec.x + (maxVec.x - minVec.x) / 2, minVec.y + (maxVec.y - minVec.y) / 2, -0.0005)
            planeNode.addChildNode(textNode)
            planeNode.simdPivot = simd_float4x4([
                simd_float4.init(x: 1, y: 0, z: 0, w: 0),
                simd_float4.init(x: 0, y: 1, z: 0, w: 0),
                simd_float4.init(x: 0, y: 0, z: 1, w: 0),
                simd_float4.init(x: 0, y: 0, z: -1.001, w: 1)
            ])
            
            switch index {
            case 0:
                planeNode.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
                
            case 1:
                planeNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: .pi / 2)
                
            case 2:
                planeNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: .pi)

            case 3:
                planeNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: .pi * 3 / 2)

            case 4:
                planeNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: -.pi / 2)

            case 5:
                planeNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: .pi / 2)

            default: break
            }
            
            scene.rootNode.addChildNode(planeNode)

        }
        
        context.coordinator.hitVectors = [
            (.left, SCNVector3(x: -10, y: 0, z: 0)),
            (.right, SCNVector3(x: 10, y: 0, z: 0)),
            (.down, SCNVector3(x: 0, y: -10, z: 0)),
            (.up, SCNVector3(x: 0, y: 10, z: 0))
        ]
        
        context.coordinator.transforms = .init(uniqueKeysWithValues: scene.rootNode.childNodes.filter { $0.name == nil && ($0 as! CubeNode).id != 0 && ($0 as! CubeNode).id != 2 }.map { node in
            guard let cubeNode = node as? CubeNode else { fatalError() }
            var direction : Direction = .undefined
            let transform = cubeNode.simdTransform
            let targetTransform = scene.rootNode.simdConvertTransform(transform, from: nil)
            
            switch cubeNode.id {
            case 1:
                direction = .right
            case 3:
                direction = .left
            case 4:
                direction = .up
            case 5:
                direction = .down
            default:
                break
            }
            print("Transform created for Node \(cubeNode.id+1)")
            return (direction, targetTransform)
        })
        
        let light = SCNLight()
        light.intensity = 1000
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 4, y: 4, z: 8)
        lightNode.name = "Light"
        
        let directions : [UISwipeGestureRecognizer.Direction] = [.down, .left, .right, .up]
        directions.forEach { direction in
            let swipeGesture = UISwipeGestureRecognizer()
            swipeGesture.direction = direction
            swipeGesture.addTarget(context.coordinator, action: #selector(context.coordinator.handleSwipe(_:)))
            sceneView.addGestureRecognizer(swipeGesture)
        }
        
        scene.rootNode.addChildNode(boxNode)
        scene.rootNode.addChildNode(lightNode)
        
        sceneView.scene = scene
        
        return sceneView
    }
    
    
    func updateUIView(_ uiView: SCNView, context: UIViewRepresentableContext<SceneKitObjectRepresentable>) {
        
        guard let box = uiView.scene?.rootNode.childNodes.filter({ $0.name == "Box" }).first else { return }
        
        let action = SCNAction.rotate(by: rotationValue, around: rotationAxis, duration: 0.3)
        action.timingMode = .easeInEaseOut
        
        uiView.scene?.rootNode.childNodes.filter { $0.name == nil }.forEach { $0.runAction(action) }
        box.runAction(action) {
            print("----------- NEW ROTATION ------------")
            rotationValue = 0
            rotationAxis = .init(x: 0, y: 0, z: 0)
            
            context.coordinator.hitVectors.forEach { (direction, vector) in
                let origin = SCNVector3(x: 0, y: 0, z: 0)
                guard
                    let hitTestResult = uiView.scene?.rootNode.hitTestWithSegment(from: origin, to: vector).first,
                    let node = hitTestResult.node as? CubeNode,
                    let targetTransform = context.coordinator.transforms[direction]
                else { return }
                
                node.simdTransform = targetTransform
                
//                node.simdTransform.columns.0 = targetTransform.columns.0
//                node.simdTransform.columns.1 = targetTransform.columns.1
//                node.simdTransform.columns.2 = targetTransform.columns.2
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent : SceneKitObjectRepresentable
        
        var transforms : [Direction : simd_float4x4] = [:]
        var hitVectors : [(Direction, SCNVector3)] = []
        
        init(_ parent: SceneKitObjectRepresentable) {
            self.parent = parent
        }
        
        @objc
        func handleSwipe(_ sender: UISwipeGestureRecognizer) {
            
            switch sender.direction {
            case .left:
                parent.rotationAxis = .init(x: 0, y: 1, z: 0)
                parent.rotationValue = -.pi / 2
            case .right:
                parent.rotationAxis = .init(x: 0, y: 1, z: 0)
                parent.rotationValue = .pi / 2
            case .up:
                parent.rotationAxis = .init(x: 1, y: 0, z: 0)
                parent.rotationValue = -.pi / 2
            case .down:
                parent.rotationAxis = .init(x: 1, y: 0, z: 0)
                parent.rotationValue = .pi / 2
            default: break
            }
        }
    }
    
    enum Direction {
        case left, right, up, down, front, back, undefined
    }
    
    func cloneNode(node: CubeNode, with id: Int) -> CubeNode {
        let clone = node.clone()
        clone.removeFromParentNode()
        clone.id = id
        clone.childNodes.forEach { $0.removeFromParentNode()}
        clone.geometry?.materials.first?.diffuse.contents = UIColor.red
        return clone
    }
}

class CubeNode: SCNNode {
    
    var id : Int
    
    init(id: Int, geometry: SCNGeometry?) {
        self.id = id
        super.init()
        self.geometry = geometry
    }
    
    override init() {
        id = Int.random(in: Int.min...Int.max)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
