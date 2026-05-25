//
//  ARViewContainer.swift
//  RoomLog
//
//  Created by 김도연 on 4/13/26.
//

import SwiftUI
import ARKit
import SceneKit

struct ARViewContainer: UIViewRepresentable {
    let session: ARSession

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.automaticallyUpdatesLighting = true
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSCNViewDelegate {

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return nil }
            let node = SCNNode()
            node.geometry = Self.makeGeometry(from: meshAnchor.geometry)
            return node
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return }
            node.geometry = Self.makeGeometry(from: meshAnchor.geometry)
        }

        private static func makeGeometry(from meshGeometry: ARMeshGeometry) -> SCNGeometry {
            let vertices = meshGeometry.vertices
            let faces = meshGeometry.faces

            let vertexSource = SCNGeometrySource(
                buffer: vertices.buffer,
                vertexFormat: vertices.format,
                semantic: .vertex,
                vertexCount: vertices.count,
                dataOffset: vertices.offset,
                dataStride: vertices.stride
            )

            let faceData = Data(
                bytesNoCopy: faces.buffer.contents(),
                count: faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex,
                deallocator: .none
            )
            let faceElement = SCNGeometryElement(
                data: faceData,
                primitiveType: .triangles,
                primitiveCount: faces.count,
                bytesPerIndex: faces.bytesPerIndex
            )

            let geometry = SCNGeometry(sources: [vertexSource], elements: [faceElement])

            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemCyan.withAlphaComponent(0.9)
            material.isDoubleSided = true
            material.fillMode = .fill
            material.transparency = 0.6
            material.lightingModel = .constant
            geometry.materials = [material]

            return geometry
        }
    }
}
