//
//  PLYSceneView.swift
//  RoomLog
//
//  Created by 김도연 on 5/12/26.
//

import SwiftUI
import SceneKit
import ModelIO
import SceneKit.ModelIO

struct PLYSceneView: UIViewRepresentable {
    let fileURL: URL

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .systemBackground
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true

        if let scene = loadScene(from: fileURL) {
            scnView.scene = scene
        }

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene == nil, let scene = loadScene(from: fileURL) {
            uiView.scene = scene
        }
    }

    private func loadScene(from url: URL) -> SCNScene? {
        let asset = MDLAsset(url: url)
        asset.loadTextures()
        return SCNScene(mdlAsset: asset)
    }
}
