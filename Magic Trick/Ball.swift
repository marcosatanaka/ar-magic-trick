import UIKit
import SceneKit
import ARKit

class Ball: SCNNode {
    
    let radius : CGFloat = 0.02
    
    let force = simd_make_float4(0, 0, -3, 0)
    
    override init() {
        super.init()
        
        self.geometry = SCNSphere(radius: radius)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.physicsBody?.allowsResting = true
        self.physicsBody?.isAffectedByGravity = true
        self.physicsBody?.collisionBitMask = -1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTransformation(camera: ARCamera?) {
        let cameraTransform = camera?.transform
        self.simdTransform = cameraTransform!
    }
    
    func applyForce(camera: ARCamera?) {
        let cameraTransform = camera?.transform
        let rotatedForce = simd_mul(cameraTransform!, force)
        let vectorForce = SCNVector3(x:rotatedForce.x, y:rotatedForce.y, z:rotatedForce.z)
        
        self.physicsBody?.applyForce(vectorForce, asImpulse: true)
    }
    
    func inside(hat: SCNNode) -> Bool {
        let ballPosition = self.presentation.worldPosition
        let hatBody = hat.childNode(withName: "body", recursively: true)
        var (hatBoundingBoxMin, hatBoundingBoxMax) = (hatBody?.presentation.boundingBox)!
        let size = hatBoundingBoxMax - hatBoundingBoxMin
        
        hatBoundingBoxMin = SCNVector3((hatBody?.presentation.worldPosition.x)! - size.x/2,
                                       (hatBody?.presentation.worldPosition.y)!,
                                       (hatBody?.presentation.worldPosition.z)! - size.z/2)
        hatBoundingBoxMax = SCNVector3((hatBody?.presentation.worldPosition.x)! + size.x,
                                       (hatBody?.presentation.worldPosition.y)! + size.y,
                                       (hatBody?.presentation.worldPosition.z)! + size.z)

        return
            ballPosition.x >= hatBoundingBoxMin.x  &&
            ballPosition.z >= hatBoundingBoxMin.z  &&
            ballPosition.x < hatBoundingBoxMax.x  &&
            ballPosition.y < hatBoundingBoxMax.y  &&
            ballPosition.z < hatBoundingBoxMax.z
    }
    
}
