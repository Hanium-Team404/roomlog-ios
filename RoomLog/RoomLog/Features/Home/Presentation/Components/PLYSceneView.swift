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

// MARK: - Camera Direction

enum CameraDirection: CaseIterable {
    case front, back, left, right, top, bottom

    var icon: String {
        switch self {
        case .front:  return "arrow.up"
        case .back:   return "arrow.down"
        case .left:   return "arrow.left"
        case .right:  return "arrow.right"
        case .top:    return "arrow.up.circle"
        case .bottom: return "arrow.down.circle"
        }
    }

    var label: String {
        switch self {
        case .front:  return "앞"
        case .back:   return "뒤"
        case .left:   return "좌"
        case .right:  return "우"
        case .top:    return "천장"
        case .bottom: return "바닥"
        }
    }
}

// MARK: - PLYSceneView

struct PLYSceneView: UIViewRepresentable {
    let fileURL: URL
    var defects: [DefectReportDetail] = []
    var cameraDirection: Binding<CameraDirection?>?
    var resetCamera: Binding<Bool>?

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var defects: [DefectReportDetail] = []
        weak var scnView: SCNView?
        var lastAppliedDirection: CameraDirection?

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)

            let hitResults = scnView.hitTest(location, options: [
                .searchMode: NSNumber(value: SCNHitTestSearchMode.all.rawValue)
            ])

            for hit in hitResults {
                if let defectID = findDefectID(from: hit.node),
                   let defect = defects.first(where: { $0.id == defectID }) {
                    animateCameraToDefect(defect, in: scnView)
                    return
                }
            }
        }

        private func findDefectID(from node: SCNNode) -> Int? {
            var current: SCNNode? = node
            while let n = current {
                if let name = n.name, name.hasPrefix("defect_"),
                   let id = Int(name.dropFirst("defect_".count)) {
                    return id
                }
                current = n.parent
            }
            return nil
        }

        // MARK: 하자 마커 탭 → 카메라 이동

        func animateCameraToDefect(_ defect: DefectReportDetail, in scnView: SCNView) {
            let points = defect.region3d
            guard !points.isEmpty, let cameraNode = scnView.pointOfView else { return }

            let count = Float(points.count)
            let cx = points.reduce(Float(0)) { $0 + $1.x } / count
            let cy = points.reduce(Float(0)) { $0 + $1.y } / count
            let cz = points.reduce(Float(0)) { $0 + $1.z } / count
            let center = SCNVector3(cx, cy, cz)

            let offset = defectCameraOffset(for: points, center: center, cameraNode: cameraNode)
            let target = SCNVector3(center.x + offset.x, center.y + offset.y, center.z + offset.z)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.8
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cameraNode.position = target
            cameraNode.look(at: center)
            SCNTransaction.commit()
        }

        private func defectCameraOffset(
            for points: [DefectPoint3D],
            center: SCNVector3,
            cameraNode: SCNNode
        ) -> SCNVector3 {
            let distance: Float = 3.0

            if points.count >= 3 {
                let v0 = SCNVector3(points[0].x, points[0].y, points[0].z)
                let v1 = SCNVector3(points[1].x, points[1].y, points[1].z)
                let v2 = SCNVector3(points[2].x, points[2].y, points[2].z)

                let e1x = v1.x - v0.x, e1y = v1.y - v0.y, e1z = v1.z - v0.z
                let e2x = v2.x - v0.x, e2y = v2.y - v0.y, e2z = v2.z - v0.z
                let nx = e1y * e2z - e1z * e2y
                let ny = e1z * e2x - e1x * e2z
                let nz = e1x * e2y - e1y * e2x
                let len = sqrt(nx * nx + ny * ny + nz * nz)

                if len > 1e-4 {
                    var nnx = nx / len, nny = ny / len, nnz = nz / len
                    let toCamX = cameraNode.position.x - center.x
                    let toCamY = cameraNode.position.y - center.y
                    let toCamZ = cameraNode.position.z - center.z
                    let dot = nnx * toCamX + nny * toCamY + nnz * toCamZ
                    if dot < 0 { nnx = -nnx; nny = -nny; nnz = -nnz }
                    return SCNVector3(nnx * distance, nny * distance, nnz * distance)
                }
            }

            let dx = cameraNode.position.x - center.x
            let dy = cameraNode.position.y - center.y
            let dz = cameraNode.position.z - center.z
            let dirLen = sqrt(dx * dx + dy * dy + dz * dz)
            guard dirLen > 0 else { return SCNVector3(0, 0, distance) }
            let scale = distance / dirLen
            return SCNVector3(dx * scale, dy * scale, dz * scale)
        }

        // MARK: 방향 버튼 → 카메라 이동

        func moveCamera(direction: CameraDirection, in scnView: SCNView) {
            guard let scene = scnView.scene,
                  let cameraNode = scnView.pointOfView else { return }

            let (minBound, maxBound) = scene.rootNode.boundingBox
            let centerX = (minBound.x + maxBound.x) / 2
            let centerY = (minBound.y + maxBound.y) / 2
            let centerZ = (minBound.z + maxBound.z) / 2
            let center = SCNVector3(centerX, centerY, centerZ)

            let sizeX = maxBound.x - minBound.x
            let sizeY = maxBound.y - minBound.y
            let sizeZ = maxBound.z - minBound.z
            let maxSize = max(sizeX, max(sizeY, sizeZ))
            let dist = maxSize * 1.2

            let position: SCNVector3
            switch direction {
            case .front:  position = SCNVector3(centerX, centerY, centerZ + dist)
            case .back:   position = SCNVector3(centerX, centerY, centerZ - dist)
            case .left:   position = SCNVector3(centerX - dist, centerY, centerZ)
            case .right:  position = SCNVector3(centerX + dist, centerY, centerZ)
            case .top:    position = SCNVector3(centerX, centerY + dist, centerZ)
            case .bottom: position = SCNVector3(centerX, centerY - dist, centerZ)
            }

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.6
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cameraNode.position = position
            cameraNode.look(at: center)
            SCNTransaction.commit()
        }

        // MARK: 초기화 → SceneKit 기본 시점 복원

        func resetToDefaultCamera(in scnView: SCNView) {
            guard let scene = scnView.scene,
                  let cameraNode = scnView.pointOfView else { return }

            let (minBound, maxBound) = scene.rootNode.boundingBox
            let centerX = (minBound.x + maxBound.x) / 2
            let centerY = (minBound.y + maxBound.y) / 2
            let centerZ = (minBound.z + maxBound.z) / 2
            let center = SCNVector3(centerX, centerY, centerZ)

            let sizeX = maxBound.x - minBound.x
            let sizeY = maxBound.y - minBound.y
            let sizeZ = maxBound.z - minBound.z
            let maxSize = max(sizeX, max(sizeY, sizeZ))
            let dist = maxSize * 1.5

            let position = SCNVector3(centerX, centerY, centerZ + dist)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.6
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cameraNode.position = position
            cameraNode.eulerAngles = SCNVector3(0, 0, 0)
            SCNTransaction.commit()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .systemBackground
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tap)

        if let scene = loadScene(from: fileURL) {
            updateDefectOverlays(in: scene, defects: defects)
            scnView.scene = scene

        }
        context.coordinator.defects = defects
        context.coordinator.scnView = scnView

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.defects = defects

        if uiView.scene == nil, let scene = loadScene(from: fileURL) {
            updateDefectOverlays(in: scene, defects: defects)
            uiView.scene = scene
        } else if let scene = uiView.scene {
            updateDefectOverlays(in: scene, defects: defects)
        }

        // 카메라 초기화 처리
        if let binding = resetCamera, binding.wrappedValue {
            context.coordinator.resetToDefaultCamera(in: uiView)
            context.coordinator.lastAppliedDirection = nil
            DispatchQueue.main.async { binding.wrappedValue = false }
        }

        // 카메라 방향 버튼 처리
        if let binding = cameraDirection,
           let direction = binding.wrappedValue,
           direction != context.coordinator.lastAppliedDirection {
            context.coordinator.lastAppliedDirection = direction
            context.coordinator.moveCamera(direction: direction, in: uiView)
            DispatchQueue.main.async { binding.wrappedValue = nil }
        }
        if cameraDirection?.wrappedValue == nil {
            context.coordinator.lastAppliedDirection = nil
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

            #if DEBUG
            print("[PLY] defect \(defect.id): \(points.count) points")
            for (i, p) in points.enumerated() {
                print("  [\(i)] x=\(p.x) y=\(p.y) z=\(p.z)")
            }
            #endif

            let group = SCNNode()
            group.name = "defect_\(defect.id)"

            let regionNode = createPolygonNode(points: points)
            regionNode.renderingOrder = 1
            group.addChildNode(regionNode)

            let center = centroid(of: points)
            let markerNode = createMarkerNode(
                at: center,
                title: defect.type.displayName,
                area: defect.defectArea
            )
            markerNode.renderingOrder = 10
            group.addChildNode(markerNode)

            container.addChildNode(group)
        }

        scene.rootNode.addChildNode(container)
    }

    // MARK: - Polygon

    private func createPolygonNode(points: [DefectPoint3D]) -> SCNNode {
        let vertices = points.map { SCNVector3($0.x, $0.y, $0.z) }

        var indices: [Int32] = []
        for i in 1..<(vertices.count - 1) {
            indices.append(0)
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
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
        material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.15)
        material.emission.contents = UIColor.systemBlue.withAlphaComponent(0.08)
        material.isDoubleSided = true
        material.writesToDepthBuffer = false
        material.readsFromDepthBuffer = false
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }

    // MARK: - Marker

    private func createMarkerNode(at position: SCNVector3, title: String, area: Double) -> SCNNode {
        let node = SCNNode()
        node.position = position

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
        planeMat.readsFromDepthBuffer = false
        plane.materials = [planeMat]

        let labelNode = SCNNode(geometry: plane)
        labelNode.position = SCNVector3(0, 0.5, 0)

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        node.constraints = [billboard]

        node.addChildNode(labelNode)

        return node
    }

    // MARK: - Helpers

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

// MARK: - Camera Direction Bar

struct PLYCameraDirectionBar: View {
    @Binding var direction: CameraDirection?
    @Binding var resetCamera: Bool
    @State private var selected: CameraDirection?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CameraDirection.allCases, id: \.label) { dir in
                Button {
                    selected = dir
                    direction = dir
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: dir.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(dir.label)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selected == dir ? .black : .white)
                    .frame(width: 44, height: 44)
                    .background(
                        selected == dir
                            ? AnyShapeStyle(Color.white)
                            : AnyShapeStyle(.clear),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
            }

            Divider()
                .frame(height: 28)
                .background(.white.opacity(0.3))

            Button {
                selected = nil
                resetCamera = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
    }
}
