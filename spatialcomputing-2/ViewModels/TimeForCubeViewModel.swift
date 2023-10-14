//
//  TimeForCubeViewModel.swift
//  spatialcomputing-2
//
//  Created by David Garcia on 10/13/23.
//

import Foundation
import ARKit
import RealityKit

private extension ModelEntity {
    class func createFingertip() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateSphere(radius: 0.005),
            materials: [UnlitMaterial(color: .cyan)],
            collisionShape: .generateSphere(radius: 0.005),
            mass: 0.0)
        
        entity.components.set(PhysicsBodyComponent(mode: .kinematic))
        entity.components.set(OpacityComponent(opacity: 0.0))
        
        return entity
    }
}


@MainActor class TimeForCubeViewModel: ObservableObject {
    private let session = ARKitSession()
    private let handTracking = HandTrackingProvider()
    private let sceneReconstruction = SceneReconstructionProvider()
    
    private var contentEntity = Entity()
    
    private var meshEntities = [UUID: ModelEntity]()
    
    private let fingerEntities: [HandAnchor.Chirality: ModelEntity] = [
        .left: .createFingertip(),
        .right: .createFingertip()
    ]
    
    func setupContentEntity() -> Entity {
        for entity in fingerEntities.values {
            contentEntity.addChild(entity)
        }
        
        return contentEntity
    }
    
    func runSession() async {
        do {
            try await session.run([sceneReconstruction, handTracking])
        } catch {
            print("Failed to start session: \(error)")
        }
    }
    
    func processHandUpdates() async {
        for await update in handTracking.anchorUpdates {
            let handAnchor = update.anchor
            
            guard handAnchor.isTracked else { continue }
            
            if let fingertip = handAnchor.handSkeleton?.joint(.indexFingerTip) {
                guard fingertip.isTracked else { continue }
                let originFromWrist = handAnchor.originFromAnchorTransform
//                let wristFromIndex = fingertip.rootTransform
                let wristFromIndex = fingertip.parentFromJointTransform
                let originFromIndex = originFromWrist * wristFromIndex
                
                fingerEntities[handAnchor.chirality]?.setTransformMatrix(originFromIndex, relativeTo: nil)
            } else {
                continue
            }
        }
    }
    
    func processReconstructionUpdates() async {
        for await update in sceneReconstruction.anchorUpdates {
            let meshAnchor = update.anchor
            
            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor)
            else { continue }
            
            switch update.event {
                case .added:
                    let entity = ModelEntity()
                    entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform) // TODO: may bug
                    entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                    entity.physicsBody = PhysicsBodyComponent()
                    entity.components.set(InputTargetComponent())
                    
                    meshEntities[meshAnchor.id] = entity
                    contentEntity.addChild(entity)
            case .updated:
                guard let entity = meshEntities[meshAnchor.id] else { fatalError(" failed to get mesh enttity")}
                
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform) // TODO: bug
                entity.collision?.shapes = [shape]
                
            case .removed:
                meshEntities[meshAnchor.id]?.removeFromParent()
                meshEntities.removeValue(forKey: meshAnchor.id)
                    
            }
        }
    }
    
    func addCube(tapLocation: SIMD3<Float>) {
        let placementLocation = tapLocation + SIMD3<Float>(0, 0.2, 0)
        
        let entity = ModelEntity(
            mesh: .generateBox(size: 0.1, cornerRadius: 0.0),
            materials: [SimpleMaterial(color: .systemPink, isMetallic: false)],
            collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0.1)),
            mass: 1.0)
    
        
        entity.setPosition(placementLocation, relativeTo: nil)
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        let material = PhysicsMaterialResource.generate(friction: 0.8, restitution: 0.0)
        entity.components.set(PhysicsBodyComponent(shapes: entity.collision!.shapes,
                                                   mass: 1.0,
                                                   material: material,
                                                   mode: .dynamic))
        
        contentEntity.addChild(entity)
    }
}
