//
//  spatialcomputing_2App.swift
//  spatialcomputing-2
//
//  Created by David Garcia on 10/13/23.
//

import SwiftUI
import RealityKit

@main
struct spatialcomputing_2App: App {
    @StateObject var model = TimeForCubeViewModel()
    
    var body: some SwiftUI.Scene {
        // required to move to full space to access ARKIT data
        ImmersiveSpace {
            
            // present content from view model
            RealityView { content in
                content.add(model.setupContentEntity())
            }
            .task {
                await model.runSession()
            }
            .task {
                await model.processHandUpdates()
            }
            .task {
                await model.processReconstructionUpdates()
            }
            .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded({ value in
                let location3D = value.convert(value.location3D, from: .global, to: .scene)
                model.addCube(tapLocation: location3D)
            }))
        }
    }
}
