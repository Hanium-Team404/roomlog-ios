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
    var defects: [DefectReportDetail] = []

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .systemBackground
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true

        if let scene = loadScene(from: fileURL) {
            addDefectOverlays(to: scene, defects: defects)
            scnView.scene = scene
        }

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene == nil, let scene = loadScene(from: fileURL) {
            addDefectOverlays(to: scene, defects: defects)
            uiView.scene = scene
        } else if let scene = uiView.scene {
            let hasOverlays = scene.rootNode.childNode(withName: "defectOverlay", recursively: false) != nil
            if !defects.isEmpty && !hasOverlays {
                addDefectOverlays(to: scene, defects: defects)
            }
        }
    }

    private func loadScene(from url: URL) -> SCNScene? {
        let asset = MDLAsset(url: url)
        asset.loadTextures()
        return SCNScene(mdlAsset: asset)
    }

    // MARK: - Defect Overlays

    private func addDefectOverlays(to scene: SCNScene, defects: [DefectReportDetail]) {
        print("[PLY] addDefectOverlays — defects: \(defects.count)")
        let container = SCNNode()
        container.name = "defectOverlay"

        for defect in defects {
            guard !defect.region3d.isEmpty else { continue }
            let points = defect.region3d
            print("[PLY] defect \(defect.id): \(points.count) points")

            // 1. 파란색 영역 — 꼭짓점을 순서대로 이어 polygon
            let regionNode = createPolygonNode(points: points)
            regionNode.renderingOrder = 1
            container.addChildNode(regionNode)

            // 2. 흰색 마커 — 중심점에 배치
            let center = centroid(of: points)
            let markerNode = createMarkerNode(at: center, label: defect.type.displayName)
            markerNode.renderingOrder = 2
            container.addChildNode(markerNode)

            print("[PLY] center: (\(center.x), \(center.y), \(center.z))")
        }

        scene.rootNode.addChildNode(container)
    }

    // MARK: - Polygon (순서대로 이은 삼각형 팬)

    private func createPolygonNode(points: [DefectPoint3D]) -> SCNNode {
        let vertices = points.map { SCNVector3($0.x, $0.y, $0.z) }

        // 삼각형 팬: vertex 0 기준
        var indices: [Int32] = []
        for i in 1..<(vertices.count - 1) {
            // 앞면
            indices.append(0)
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
            // 뒷면 (양면 렌더링 보장)
            indices.append(0)
            indices.append(Int32(i + 1))
            indices.append(Int32(i))
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )

        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.4)
        material.emission.contents = UIColor.systemBlue.withAlphaComponent(0.2)
        material.isDoubleSided = true
        material.writesToDepthBuffer = false  // 포인트 클라우드 위에 항상 보이게
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }

    // MARK: - Marker (흰색 구 + 라벨)

    private func createMarkerNode(at position: SCNVector3, label: String) -> SCNNode {
        let node = SCNNode()
        node.position = position

        // 흰색 구 — 모델 스케일에 맞게 크기 설정
        let sphere = SCNSphere(radius: 0.03)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.white
        sphereMaterial.emission.contents = UIColor.white.withAlphaComponent(0.5)
        sphereMaterial.writesToDepthBuffer = false
        sphere.materials = [sphereMaterial]
        let sphereNode = SCNNode(geometry: sphere)
        node.addChildNode(sphereNode)

        // 라벨
        let text = SCNText(string: label, extrusionDepth: 0.2)
        text.font = UIFont.systemFont(ofSize: 2, weight: .bold)
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.white
        textMaterial.emission.contents = UIColor.white
        textMaterial.writesToDepthBuffer = false
        text.materials = [textMaterial]
        text.flatness = 0.2

        let textNode = SCNNode(geometry: text)
        let (minBound, maxBound) = textNode.boundingBox
        let textWidth = maxBound.x - minBound.x
        textNode.pivot = SCNMatrix4MakeTranslation(textWidth / 2, 0, 0)
        textNode.position = SCNVector3(0, 0.05, 0)
        textNode.scale = SCNVector3(0.02, 0.02, 0.02)

        // 배경 판
        let bgWidth = CGFloat(textWidth * 0.02 + 0.02)
        let bgHeight: CGFloat = 0.06
        let bgPlane = SCNPlane(width: bgWidth, height: bgHeight)
        let bgMaterial = SCNMaterial()
        bgMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.6)
        bgMaterial.writesToDepthBuffer = false
        bgPlane.materials = [bgMaterial]
        bgPlane.cornerRadius = bgHeight / 4

        let bgNode = SCNNode(geometry: bgPlane)
        bgNode.position = SCNVector3(0, 0.05 + Float(bgHeight) / 2 - 0.01, -0.001)

        // 빌보드 — 항상 카메라를 향하게
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        node.constraints = [billboard]

        node.addChildNode(textNode)
        node.addChildNode(bgNode)

        return node
    }

    // MARK: - Helpers

    private func centroid(of points: [DefectPoint3D]) -> SCNVector3 {
        let n = Float(points.count)
        let x = points.reduce(0 as Float) { $0 + $1.x } / n
        let y = points.reduce(0 as Float) { $0 + $1.y } / n
        let z = points.reduce(0 as Float) { $0 + $1.z } / n
        return SCNVector3(x, y, z)
    }
}
