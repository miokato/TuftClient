//
//  PlacementManager.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import ARKit
import RealityKit
import AVFoundation

@Observable
final class AppManager {
    private let worldTracking = WorldTrackingProvider()
    private let session = ARKitSession()
    private let provider = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
    
    private let deviceLocation: Entity
    private let raycastOrigin: Entity
    private let placementLocation: Entity
    public let rootEntity: Entity

    var entityMap: [UUID: Entity] = [:]
    
    init() {
        raycastOrigin = Entity()
        deviceLocation = Entity()
        placementLocation = Entity()
        rootEntity = Entity()
        
        rootEntity.addChild(placementLocation)
        deviceLocation.addChild(raycastOrigin)
        
        // Angle raycasts 15 degrees down.
        let raycastDownwardAngle = 15.0 * (Float.pi / 180)
        raycastOrigin.orientation = simd_quatf(angle: -raycastDownwardAngle, axis: [1.0, 0.0, 0.0])
    }
    
    func run() async {
        guard PlaneDetectionProvider.isSupported else { return }

        do {
            try await session.run([provider])
            for await update in provider.anchorUpdates {
                if update.anchor.classification == .window { continue }

                switch update.event {
                case .added, .updated:
                    await updatePlane(update.anchor)
                case .removed:
                    removePlane(update.anchor)
                }
            }
        } catch {
            print("ARKit session error \(error)")
        }
    }

    /// 平面の更新
    @MainActor
    func updatePlane(_ anchor: PlaneAnchor) {
        if let entity = entityMap[anchor.id] {
        } else {
            if anchor.classification == .table {
                let entity = createPlane(anchor.geometry.extent.anchorFromExtentTransform)
                entityMap[anchor.id] = entity
                rootEntity.addChild(entity)
            }
        }
        
        // originFromAnchorTransform: The location and orientation of a plane in world space.
        entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
    }
    
    /// 平面の削除
    func removePlane(_ anchor: PlaneAnchor) {
        entityMap[anchor.id]?.removeFromParent()
        entityMap.removeValue(forKey: anchor.id)
    }
    
    /// 平面を作成
    func createPlane(_ matrix: simd_float4x4) -> ModelEntity {
        let plane = ModelEntity(mesh: .generatePlane(width: 0.4, depth: 0.4, cornerRadius: 0.1))
        
        let asset = AVURLAsset(url: Bundle.main.url(forResource: "normal_01_1", withExtension: "mp4")!)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer()
        player.replaceCurrentItem(with: playerItem)
        player.play()
        let material = VideoMaterial(avPlayer: player)
        
        plane.transform = Transform(matrix: matrix)
        plane.model?.materials = [material]
        plane.name = "bot"
        return plane
    }
}

extension PlaneAnchor {
    static let horizontalCollisionGroup = CollisionGroup(rawValue: 1 << 31)
    static let verticalCollisionGroup = CollisionGroup(rawValue: 1 << 30)
    static let allPlanesCollisionGroup = CollisionGroup(rawValue: horizontalCollisionGroup.rawValue | verticalCollisionGroup.rawValue)
}

extension MeshResource.Contents {
    init(planeGeometry: PlaneAnchor.Geometry) {
        self.init()
        self.instances = [MeshResource.Instance(id: "main", model: "model")]
        var part = MeshResource.Part(id: "part", materialIndex: 0)
        part.positions = MeshBuffers.Positions(planeGeometry.meshVertices.asSIMD3(ofType: Float.self))
        part.triangleIndices = MeshBuffer(planeGeometry.meshFaces.asUInt32Array())
        self.models = [MeshResource.Model(id: "model", parts: [part])]
    }
}
