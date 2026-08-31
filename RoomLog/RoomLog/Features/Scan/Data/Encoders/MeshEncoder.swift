//
//  MeshEncoder.swift
//  RoomLog
//
//  Created by 김도연 on 5/26/26.
//

import ARKit

final class MeshEncoder {
    private let fileURL: URL

    init(outputURL: URL) {
        self.fileURL = outputURL
    }

    /// ARMeshAnchor 배열을 PLY 파일로 저장
    func encode(anchors: [ARMeshAnchor]) throws {
        var totalVertexCount = 0
        var totalFaceCount = 0

        // 전체 vertex/face 수 계산
        for anchor in anchors {
            totalVertexCount += anchor.geometry.vertices.count
            totalFaceCount += anchor.geometry.faces.count
        }

        var result = ""
        result.reserveCapacity(totalVertexCount * 40 + totalFaceCount * 30)

        // PLY 헤더
        result += "ply\n"
        result += "format ascii 1.0\n"
        result += "element vertex \(totalVertexCount)\n"
        result += "property float x\n"
        result += "property float y\n"
        result += "property float z\n"
        result += "element face \(totalFaceCount)\n"
        result += "property list uchar int vertex_indices\n"
        result += "end_header\n"

        // Vertex 데이터
        var vertexOffset: Int = 0

        for anchor in anchors {
            let geometry = anchor.geometry
            let transform = anchor.transform
            let vertexSource = geometry.vertices
            let vertexBuffer = vertexSource.buffer.contents()

            for i in 0..<vertexSource.count {
                let ptr = vertexBuffer.advanced(by: vertexSource.offset + i * vertexSource.stride)
                let localPos = ptr.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                let worldPos = transform * SIMD4<Float>(localPos, 1.0)
                result += "\(worldPos.x) \(worldPos.y) \(worldPos.z)\n"
            }

            vertexOffset += vertexSource.count
        }

        // Face 데이터
        vertexOffset = 0

        for anchor in anchors {
            let geometry = anchor.geometry
            let faceElement = geometry.faces
            let faceBuffer = faceElement.buffer.contents()
            let indicesPerFace = faceElement.indexCountPerPrimitive

            for i in 0..<faceElement.count {
                var indices: [Int] = []
                for j in 0..<indicesPerFace {
                    let indexOffset = (i * indicesPerFace + j) * faceElement.bytesPerIndex
                    let ptr = faceBuffer.advanced(by: indexOffset)
                    let index: Int
                    if faceElement.bytesPerIndex == 4 {
                        index = Int(ptr.assumingMemoryBound(to: UInt32.self).pointee)
                    } else {
                        index = Int(ptr.assumingMemoryBound(to: UInt16.self).pointee)
                    }
                    indices.append(index + vertexOffset)
                }
                result += "\(indicesPerFace) \(indices.map(String.init).joined(separator: " "))\n"
            }

            vertexOffset += geometry.vertices.count
        }

        try result.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
