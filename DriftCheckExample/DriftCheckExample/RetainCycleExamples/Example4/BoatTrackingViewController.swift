import UIKit

class BoatTrackingViewController: UIViewController {
    
    let boatID = UUID().uuidString
    private var timer: Timer?
    private var currentWaypointIndex = 0
    private var previousPosition: CGPoint = .zero
    private var tickCount = 0
    
    // Waypoints as percentages of screen width/height
    private let normalizedWaypoints: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.2, y: 0.2),
        CGPoint(x: 0.35, y: 0.62),
        CGPoint(x: 0.5, y: 0.55),
        CGPoint(x: 0.65, y: 0.6),
        CGPoint(x: 0.8, y: 0.53),
        CGPoint(x: 0.95, y: 0.58)
    ]
    
    var actualWayPoints: [CGPoint] {
        normalizedWaypoints.map { point in
            CGPoint(x: point.x * view.bounds.width,
                    y: point.y * view.bounds.height)
        }
    }
    
    let boatOptions = [
        "🚤",
        "⛵",
        "🚣‍♀️",
        "🚣‍♀️",
     ]
    
    lazy var boat: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 50, weight: .bold)
        label.textColor = .label
        label.text = boatOptions.randomElement()
        label.sizeToFit()
        return label
    }()
    
    lazy var waterView: UIView = {
        let waterView = WaterSurfaceView()
        waterView.translatesAutoresizingMaskIntoConstraints = false
        tether(waterView)
        return waterView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .blue

        view.addSubview(waterView)
        waterView.pin(to: view)

        view.addSubview(boat)
        moveToNextWaypoint()
        startTimer()
        self.navigationController?.navigationBar.tintColor = .white
        // Extra wait time since animations can extend past dismissal
        self.retentionMode = .onRemovalFromHierarchy(waitFrames: 60)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.moveToNextWaypoint()
            }
        }
    }
    
    private func moveToNextWaypoint() {
        let actualWaypoints = actualWayPoints
        guard !actualWaypoints.isEmpty else { return }
        
        let nextIndex = (currentWaypointIndex + 1) % actualWaypoints.count
        let nextPoint = actualWaypoints[nextIndex]
        
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500
        transform = CATransform3DRotate(transform, .pi, 0, nextPoint.x > boat.center.x ? 1: 0, 0)
        
        UIView.animate(withDuration: 0.1, animations: {
            self.boat.layer.transform = transform
        })
        
        UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseInOut]) {
            self.boat.center = nextPoint
        } completion: { _ in
            let sonarSize: CGFloat = 100
            let sonarFrame = CGRect(
                x: nextPoint.x - sonarSize / 2,
                y: nextPoint.y - sonarSize / 2,
                width: sonarSize,
                height: sonarSize
            )
            let sonar = SonarPingView(frame: sonarFrame)
            self.tether(sonar)
            self.view.insertSubview(sonar, belowSubview: self.boat)
        }
        
        previousPosition = nextPoint
        currentWaypointIndex = nextIndex
        
        print("Boat id \(boatID) location updated to: \(nextPoint)")
    }
    
    deinit {
        timer?.invalidate()
    }
}
