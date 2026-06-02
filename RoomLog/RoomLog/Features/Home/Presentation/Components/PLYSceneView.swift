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
            updateDefectOverlays(in: scene, defects: defects)
            scnView.scene = scene
        }

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene == nil, let scene = loadScene(from: fileURL) {
            updateDefectOverlays(in: scene, defects: defects)
            uiView.scene = scene
        } else if let scene = uiView.scene {
            updateDefectOverlays(in: scene, defects: defects)
        }
    }

    private func loadScene(from url: URL) -> SCNScene? {
        let asset = MDLAsset(url: url)
        asset.loadTextures()
        return SCNScene(mdlAsset: asset)
    }

    // MARK: - Defect Overlays

    private func updateDefectOverlays(in scene: SCNScene, defects: [DefectReportDetail]) {
        scene.rootNode.childNode(withName: "defectOverlay", recursively: false)?.removeFromParentNode()
        guard defects.contains(where: { !$0.region3d.isEmpty }) else { return }
        addDefectOverlays(to: scene, defects: defects)
    }

    private func addDefectOverlays(to scene: SCNScene, defects: [DefectReportDetail]) {
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

            // 2. 마커 — 중심점에 하자 이름 + 면적 표시
            let center = centroid(of: points)
            let markerNode = createMarkerNode(
                at: center,
                title: defect.type.displayName,
                area: defect.defectArea
            )
            markerNode.renderingOrder = 10
            container.addChildNode(markerNode)
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

    private func createMarkerNode(at position: SCNVector3, title: String, area: Double) -> SCNNode {
        let node = SCNNode()
        node.position = position

        // 라벨 — UIImage 텍스처로 렌더링 (하자 이름 + 면적)
        let areaText = String(format: "%.2f m²", area)
        let labelImage = renderLabel(title: title, subtitle: areaText)
        let aspect = labelImage.size.width / labelImage.size.height
        let planeHeight: CGFloat = 0.8
        let planeWidth = planeHeight * aspect
        let plane = SCNPlane(width: planeWidth, height: planeHeight)
        let planeMat = SCNMaterial()
        planeMat.diffuse.contents = labelImage
        planeMat.emission.contents = labelImage
        planeMat.isDoubleSided = true
        planeMat.writesToDepthBuffer = false
        plane.materials = [planeMat]

        let labelNode = SCNNode(geometry: plane)
        labelNode.position = SCNVector3(0, 0.5, 0)

        // 빌보드 — 항상 카메라를 향하게
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        node.constraints = [billboard]

        node.addChildNode(labelNode)

        return node
    }

    // MARK: - Helpers

    /// 하자 이름 + 면적을 둥근 배경의 UIImage로 렌더링
    private func renderLabel(title: String, subtitle: String) -> UIImage {
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 28, weight: .semibold)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.85)
        ]

        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        let subtitleSize = (subtitle as NSString).size(withAttributes: subtitleAttrs)

        let padding: CGFloat = 24
        let lineSpacing: CGFloat = 8
        let contentWidth = max(titleSize.width, subtitleSize.width)
        let contentHeight = titleSize.height + lineSpacing + subtitleSize.height
        let size = CGSize(width: contentWidth + padding * 2, height: contentHeight + padding * 1.5)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 20)
            UIColor.black.withAlphaComponent(0.75).setFill()
            path.fill()

            let titleOrigin = CGPoint(x: padding, y: padding * 0.6)
            (title as NSString).draw(at: titleOrigin, withAttributes: titleAttrs)

            let subtitleOrigin = CGPoint(x: padding, y: padding * 0.6 + titleSize.height + lineSpacing)
            (subtitle as NSString).draw(at: subtitleOrigin, withAttributes: subtitleAttrs)
        }
    }

    private func centroid(of points: [DefectPoint3D]) -> SCNVector3 {
        let n = Float(points.count)
        let x = points.reduce(0 as Float) { $0 + $1.x } / n
        let y = points.reduce(0 as Float) { $0 + $1.y } / n
        let z = points.reduce(0 as Float) { $0 + $1.z } / n
        return SCNVector3(x, y, z)
    }
}
