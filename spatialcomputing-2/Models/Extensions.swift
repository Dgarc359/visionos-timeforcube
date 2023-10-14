//
//  Extensions.swift
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

