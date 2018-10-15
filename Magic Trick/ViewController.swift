import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var magicButton: UIButton!
    @IBOutlet weak var throwBallButton: UIButton!
    @IBOutlet weak var guideLabel: UILabel!

    private var hat: SCNNode!
    private var balls = [Ball]()
    private var magicSound: SCNAudioSource!
    private var throwSound: SCNAudioSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.scene = SCNScene()

        magicSound = SCNAudioSource(fileNamed: "art.scnassets/magic.wav")
        throwSound = SCNAudioSource(fileNamed: "art.scnassets/throw.aiff")
        magicSound.load()
        throwSound.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Check the number of degrees of freedom available on the device
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
        } else {
            let configuration = AROrientationTrackingConfiguration()
            sceneView.session.run(configuration)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - Actions

    @IBAction func touchedThrowBall(_ sender: UIButton) {
        // Instantiate a ball, put it in front of camera and throw it forward
        let ballNode = Ball()
        ballNode.applyTransformation(camera: sceneView.session.currentFrame?.camera)
        sceneView.scene.rootNode.addChildNode(ballNode)
        ballNode.applyForce(camera: sceneView.session.currentFrame?.camera)

        // Play a sound to the thrown ball
        ballNode.runAction(SCNAction.playAudio(throwSound, waitForCompletion: false))
        balls.append(ballNode)
    }

    @IBAction func touchedMagic(_ sender: UIButton) {
        // Add a particle effect
        let sparkles = SCNParticleSystem(named: "Sparkles", inDirectory: nil)!
        hat?.addParticleSystem(sparkles)

        // Hide the balls that are inside the hat
        balls.filter { $0.inside(hat: hat) }
             .forEach { $0.isHidden = !$0.isHidden }

        // Play magic sound and, when finished, removes the particle effect
        hat?.runAction(SCNAction.playAudio(magicSound, waitForCompletion: true)) {
            self.hat?.removeParticleSystem(sparkles)
        }
    }

    // Hiding/showing debug information
    @IBAction func tapDebug(_ sender: Any) {
        if sceneView.debugOptions.isEmpty {
            sceneView.debugOptions = [.showPhysicsShapes]
            sceneView.showsStatistics = true
        } else {
            sceneView.debugOptions = []
            sceneView.showsStatistics = false
        }
    }

}

extension ViewController: ARSCNViewDelegate {

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if self.hat != nil { return nil }

        if (anchor as? ARPlaneAnchor) == nil {
            return nil
        }

        return SCNNode()
    }

    // Add hat to the node added to the view`s session
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            NSLog("Is not ARPlaneAnchor")
            return
        }

        if let hat = createHatFromScene(SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)) {
            node.addChildNode(hat)
            self.hat = hat
            DispatchQueue.main.async {
                self.guideLabel.removeFromSuperview()
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Adjust light intensity accordingly to the ambient light
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            sceneView.scene.rootNode.childNode(withName: "omni", recursively: true)?.light?.intensity = lightEstimate.ambientIntensity
        }
    }

    private func createHatFromScene(_ position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "art.scnassets/hat", withExtension: "scn") else {
            NSLog("Could not find hat scene")
            return nil
        }

        guard let node = SCNReferenceNode(url: url) else { return nil }
        node.position = position
        node.load()

        NSLog("Created hat")
        return node
    }

}
