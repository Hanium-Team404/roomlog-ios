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
        // 에셋 색상 심볼은 MainActor 격리라 여기서 읽어 넘긴다 (UIColor는 Sendable)
        Coordinator(meshColor: .accent)
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

    /// ARSCNView는 델리게이트를 SceneKit 렌더링 큐에서 부른다. 기본 격리(MainActor)로 두면
    /// Swift 6 모드의 런타임 격리 검사가 렌더링 큐에서 실패해 크래시하므로 격리에서 제외한다.
    /// 상태 없이 메시 지오메트리만 만들어 돌려주므로 메인 액터가 필요하지 않다.
    nonisolated final class Coordinator: NSObject, ARSCNViewDelegate {
        private let meshColor: UIColor

        init(meshColor: UIColor) {
            self.meshColor = meshColor
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return nil }
            let node = SCNNode()
            node.geometry = makeGeometry(from: meshAnchor.geometry)
            return node
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let meshAnchor = anchor as? ARMeshAnchor else { return }
            node.geometry = makeGeometry(from: meshAnchor.geometry)
        }

        private func makeGeometry(from meshGeometry: ARMeshGeometry) -> SCNGeometry {
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
            material.diffuse.contents = meshColor
            material.isDoubleSided = true
            material.fillMode = .fill
            material.transparency = 0.6
            material.lightingModel = .constant
            geometry.materials = [material]

            return geometry
        }
    }
}
