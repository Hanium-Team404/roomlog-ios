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

        /// Handles a tap on the SceneKit view and, if a defect overlay was tapped, animates the camera to that defect's center.
        /// - Parameters:
        ///   - gesture: The tap gesture recognizer whose touch location is hit-tested against the SCNView to locate defect nodes.
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

        /// Finds a defect identifier encoded in a node's name or any of its ancestor nodes.
        /// - Parameter node: The starting `SCNNode` to inspect; the search moves upward through `parent` links.
        /// - Returns: The integer parsed from a name matching the pattern `"defect_<id>"`, or `nil` if no matching node is found.
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

        /// Animates the scene camera to frame and look at the specified defect region.
        /// 
        /// If `defect.region3d` is empty or `scnView.pointOfView` is missing, the function returns without changes.
        /// - Parameters:
        ///   - defect: The defect whose 3D region will be used to compute the camera target.
        ///   - scnView: The SceneKit view containing the camera to animate.

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

        /// Computes a camera offset vector positioned at a fixed distance from the defect region center, oriented along the region's estimated face normal when available or toward the current camera otherwise.
        /// - Parameters:
        ///   - points: 3D points defining the defect region; the first three points are used to estimate a face normal.
        ///   - center: Centroid of the defect region.
        ///   - cameraNode: Current camera node used to choose the normal direction or as fallback orientation.
        /// - Returns: An `SCNVector3` whose length is approximately 3.0, pointing from the region center toward the camera-facing side (or directly toward the camera if a reliable normal cannot be computed).
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

        /// Moves the scene's camera to a preset viewpoint for the specified direction, animating the transition.
        /// - Parameters:
        ///   - direction: The target `CameraDirection` (front/back/left/right/top/bottom) to move the camera toward.
        ///   - scnView: The `SCNView` whose scene and `pointOfView` camera will be repositioned. If the scene or camera is missing, the function has no effect.
        /// - Note: The camera is positioned relative to the scene's root-node bounding box center and the transition is animated (0.6s, ease in/out).

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

        /// Reset the scene camera to a default viewpoint that frames the scene's root node.
        /// 
        /// The camera is moved to a position directly above the scene center at a distance equal to 1.5 × the scene's maximum axis size, the camera's orientation is reset (zeroed Euler angles), and the change is animated with a 0.6s ease-in-out transition. If the view has no scene or pointOfView, the call does nothing.
        /// - Parameter scnView: The `SCNView` whose pointOfView (camera) will be reset.

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

    /// Creates a new coordinator to manage SceneKit interactions and runtime state.
    /// - Returns: A `Coordinator` instance responsible for gesture handling, defect interaction, and camera control.
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Creates and configures an `SCNView` for SwiftUI integration, attaches a tap gesture that forwards taps to the coordinator, loads the scene from `fileURL` and applies defect overlays, and wires the coordinator's runtime state.
    /// - Returns: A configured `SCNView` ready for display and interaction.
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

    /// Updates the provided `SCNView` with the loaded scene and defect overlays, and responds to camera control bindings (move direction or reset).
    /// - Parameters:
    ///   - uiView: The `SCNView` to update; the function will load a scene if needed and refresh defect overlay nodes.
    ///   - context: The SwiftUI `Context` containing the coordinator used to perform camera animations and maintain coordinator state.
    /// - Note: This method may trigger camera animations via the coordinator and will clear `resetCamera` / `cameraDirection` bindings after applying their effects.
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

    /// Create an `SCNScene` from a Model I/O asset at the specified file URL.
    /// - Parameters:
    ///   - url: File URL of the 3D model to load.
    /// - Returns: An `SCNScene` constructed from the model asset, or `nil` if the scene could not be created.
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

    /// Adds visual overlays for each defect to the given scene.
    /// 
    /// Creates a top-level container node named "defectOverlay" and, for every defect that has a non-empty `region3d`,
    /// adds a child group node named "defect_<id>" containing:
    /// - a filled polygon region node representing the defect area, and
    /// - a marker node positioned at the region centroid showing the defect type and area.
    /// Defects with empty `region3d` are skipped.
    — Parameters:
    ///   - scene: The SceneKit scene to which defect overlay nodes will be added.
    ///   - defects: An array of defect details; each defect's `region3d` provides the polygon vertices and is used to build the overlay.
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

    /// Creates an SCNNode representing a filled polygon defined by the given 3D points, rendered with a translucent blue material.
    /// - Parameters:
    ///   - points: Ordered vertices of the polygon in 3D space; must contain at least three points to form a polygon.
    /// - Returns: An `SCNNode` whose geometry is the filled polygon with a semi-transparent blue material.

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

    /// Creates a marker node with a billboarded image label showing the given title and formatted area at the specified 3D position.
    /// - Parameters:
    ///   - position: World-space position where the marker will be placed.
    ///   - title: Title text displayed on the label.
    ///   - area: Area in square meters; rendered as a string formatted to two decimal places (e.g. "12.34 m²").
    /// - Returns: An `SCNNode` positioned at `position` containing a textured plane that faces the camera and displays the title and area.

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

    /// Renders a rounded label image combining a title and subtitle for use as a 3D marker texture.
    /// - Parameters:
    ///   - title: The primary text displayed prominently at the top of the label.
    ///   - subtitle: The secondary text displayed below the title with reduced emphasis.
    /// - Returns: A `UIImage` sized to fit the text that contains a semi-transparent black rounded background with the title (bold, white) and subtitle (semibold, white at reduced alpha) drawn centered vertically with padding.

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

    /// Computes the centroid (arithmetic mean) of the given 3D defect points.
    /// - Parameter points: Array of `DefectPoint3D` whose coordinates will be averaged; must contain at least one element.
    /// - Returns: An `SCNVector3` representing the average x, y and z coordinates of the input points.
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
