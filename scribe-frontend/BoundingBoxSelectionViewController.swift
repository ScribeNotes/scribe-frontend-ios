import UIKit

class BoundingBoxSelectionViewController: UIViewController {
    var startPoint: CGPoint?
    var endPoint: CGPoint?
    var selectionRectLayer: CAShapeLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            startPoint = gestureRecognizer.location(in: view)
            endPoint = startPoint
            updateSelectionRect()
        case .changed:
            endPoint = gestureRecognizer.location(in: view)
            updateSelectionRect()
        case .ended, .cancelled:
            startPoint = nil
            endPoint = nil
            removeSelectionRect()
        default:
            break
        }
    }

    func updateSelectionRect() {
        if let startPoint = startPoint, let endPoint = endPoint {
            let rect = CGRect(x: min(startPoint.x, endPoint.x),
                              y: min(startPoint.y, endPoint.y),
                              width: abs(startPoint.x - endPoint.x),
                              height: abs(startPoint.y - endPoint.y))

            if selectionRectLayer == nil {
                selectionRectLayer = CAShapeLayer()
                selectionRectLayer?.strokeColor = UIColor.red.cgColor
                selectionRectLayer?.fillColor = UIColor.clear.cgColor
                view.layer.addSublayer(selectionRectLayer!)
            }

            let path = UIBezierPath(rect: rect)
            selectionRectLayer?.path = path.cgPath
        }
    }

    func removeSelectionRect() {
        selectionRectLayer?.removeFromSuperlayer()
        selectionRectLayer = nil
    }
}
