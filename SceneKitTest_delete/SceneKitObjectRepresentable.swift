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
    
    private let animationDuration : Double = 0.3
    
    //Called only once when the view is created
    func makeUIView(context: UIViewRepresentableContext<SceneKitObjectRepresentable>) -> SCNView {
        let sceneView = SCNView()
        sceneView.frame = .zero
        
        let scene = SCNScene()
        
        let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.2)
        box.firstMaterial?.diffuse.contents = UIColor.white
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "Box"
        
        for (index, element) in cubeElements.enumerated() {
            let text = SCNText(string: "Test\(element)", extrusionDepth: 0.01)
            text.firstMaterial?.diffuse.contents = UIColor.black
            text.font = UIFont(name: "system", size: 16)
            text.flatness = 0.1
            
            let textNode = SCNNode(geometry: text)
            
            // Move the text's anchor point to its center (by default it's at the bottom left) and scale the text by 0.05
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
            // Add the textNode to the plane and set its anchor point to be the middle of the box (last column, z-value)
            planeNode.addChildNode(textNode)
            planeNode.simdPivot = simd_float4x4([
                simd_float4.init(x: 1, y: 0, z: 0, w: 0),
                simd_float4.init(x: 0, y: 1, z: 0, w: 0),
                simd_float4.init(x: 0, y: 0, z: 1, w: 0),
                simd_float4.init(x: 0, y: 0, z: -1.001, w: 1)
            ])
            
            //Rotate the planes around their new center (origin node) according to their id
            switch index {
            case 0:
                planeNode.simdRotation = simd_float4(x: 0, y: 0, z: 0, w: 0)
            case 1:
                planeNode.simdRotation = simd_float4(x: 0, y: 1, z: 0, w: .pi / 2)
            case 2:
                planeNode.simdRotation = simd_float4(x: 0, y: 1, z: 0, w: .pi)
            case 3:
                planeNode.simdRotation = simd_float4(x: 0, y: 1, z: 0, w: .pi * 3 / 2)
            case 4:
                planeNode.simdRotation = simd_float4(x: 1, y: 0, z: 0, w: -.pi / 2)
            case 5:
                planeNode.simdRotation = simd_float4(x: 1, y: 0, z: 0, w: .pi / 2)
            default: break
            }
            
            //Add plane to root node (NOT to the box to preserve world geometry)
            scene.rootNode.addChildNode(planeNode)

        }
        
        //Create hit vectors that (further down) test which nodes are at the top, the bottom, the left and the right of the cube to rotate them
        context.coordinator.hitVectors = [
            (.left, SCNVector3(x: -10, y: 0, z: 0)),
            (.right, SCNVector3(x: 10, y: 0, z: 0)),
            (.down, SCNVector3(x: 0, y: -10, z: 0)),
            (.up, SCNVector3(x: 0, y: 10, z: 0))
        ]
        
        // Save the original transforms of the nodes at the top, the bottom, the left and the right to later apply them to the nodes found by the hit vectors
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
        
        //Create a light source to actually see 3D shapes
        let light = SCNLight()
        light.intensity = 1000
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 4, y: 4, z: 8)
        lightNode.name = "Light"
        
        // Install four distinct swipe gesture recognizers for every direction
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
    
    //Called whenever a property marked with "@State" changes
    func updateUIView(_ uiView: SCNView, context: UIViewRepresentableContext<SceneKitObjectRepresentable>) {
        
        //Get the cube from the SCNView
        guard let box = uiView.scene?.rootNode.childNodes.filter({ $0.name == "Box" }).first else { return }
        
        //Make rotation action for the cube and the plane nodes (with the text attached)
        let action = SCNAction.rotate(by: rotationValue, around: rotationAxis, duration: animationDuration)
        action.timingMode = .easeInEaseOut
        
        //Disable swipes until the cube has settled to prevent faulty plane rotations
        uiView.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration + 0.25)) {
            uiView.isUserInteractionEnabled = true
        }
        
        //Run the actions on both the cube and the plane nodes
        uiView.scene?.rootNode.childNodes.filter { $0.name == nil }.forEach { $0.runAction(action) }
        box.runAction(action) {
            //Completion handler (after rotation):
            //Reset the rotation value and rotation axis
            rotationValue = 0
            rotationAxis = .init(x: 0, y: 0, z: 0)
            
            //Perform a hit test in all four directions from the center of the cube (to the left, right, top and bottom)
            //to check which nodes are currently at those positions, and set their transforms to be equal to those of the nodes who
            //were originally there. This prevents cube faces facing the wrong way.
            context.coordinator.hitVectors.forEach { (direction, vector) in
                let origin = SCNVector3(x: 0, y: 0, z: 0)
                guard
                    let hitTestResult = uiView.scene?.rootNode.hitTestWithSegment(from: origin, to: vector).first,
                    let node = hitTestResult.node as? CubeNode,
                    let targetTransform = context.coordinator.transforms[direction]
                else { return }
                
                DispatchQueue.main.async {
                    node.simdTransform = targetTransform
                }
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
}

//Subclass SCNNode to enable it to hold an 'id' property for later identification
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
