//
//  CanvasPage.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/13/23.
//

import PencilKit
import UIKit
import SwiftDraw
import PocketSVG

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
extension PKStroke: Equatable {
    public static func ==(lhs: PKStroke, rhs: PKStroke) -> Bool {
        return (lhs as PKStrokeReference) === (rhs as PKStrokeReference)
    }
}

class LineView: UIView {
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(2.0)
        context?.move(to: CGPoint(x: 10, y: rect.size.height / 2))
        context?.addLine(to: CGPoint(x: rect.size.width - 10, y: rect.size.height / 2))
        context?.strokePath()
    }
}

class CanvasPage: UIViewController, PKCanvasViewDelegate,UITextFieldDelegate {
    
    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()
    let pageView = UIView()
    //scroll variables
    let pageAspectRatio = 8.5/11
    var pageWidth: CGFloat = 0 //set in viewDidLoad
    var pageHeight:CGFloat = 0 //set in viewDidLoad
    var canvasOverscrollHeight: CGFloat = 0 //set in viewDidLoad
    var pageBreakLayer: CAShapeLayer = CAShapeLayer()
    var pageLayer:CAShapeLayer = CAShapeLayer()
    let containerLayer = CALayer()
    
    //Utilities
    let toolPicker = PKToolPicker()
    @IBOutlet weak var pencilFingerButton: UIButton!
    
    
    //ViewController Setup
    override func viewDidLoad(){
        
        super.viewDidLoad()
        //canvasView setup
        canvasView.drawing = PKDrawing()
        canvasView.delegate = self
        canvasView.bounces = false
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false
        canvasView.bouncesZoom = true
        canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.anyInput
        
        //Page setup
        pageWidth = view.bounds.width
        pageHeight = 1/pageAspectRatio * pageWidth
        canvasOverscrollHeight = pageHeight
        
        // UI Setup
        pencilFingerButton.setTitle("Pencil", for: UIControl.State.normal)
        navigationController?.navigationBar.backgroundColor = UIColor.white
        
        //View Setup
        view.addSubview(canvasView)
        view.backgroundColor = UIColor(hex: "#dccfbc")
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = true
        
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        canvasView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        let canvasScale = canvasView.bounds.width / pageWidth
        canvasView.minimumZoomScale = 0.5
        canvasView.maximumZoomScale = 5
        canvasView.zoomScale = canvasScale
        updateContentSizeForDrawing()
        redrawPageBreaks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool{
        return true
    }
    
    
    
    

// Button Callbacks
    @IBAction func add_page(_ sender: Any){
        addPage()
    }
    @IBAction func evaluate(_ sender: Any) {
        print("evaluate")
        var (selectionDrawing, placementPoint) = getLassoSelection()
        
        let selection_ink = selectionDrawing.strokes[0].ink
        let sample_point = selectionDrawing.strokes[0].path[0]
        
        let svg = PKDrawingToSVG(drawing: selectionDrawing)
        
        var startTime = DispatchTime.now()
        sendPostRequest(with: svg) { result in
            switch result {
            case .success(let responseSVG):
                var endTime = DispatchTime.now()
                var nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                var timeInterval = Double(nanoTime) / 1_000_000_000 // Convert to seconds
                print("request time: \(timeInterval) seconds")
                let strokes = SVGtoStroke(svg:responseSVG, placementPoint: placementPoint, ink: selection_ink, samplePoint: sample_point, target_height: selectionDrawing.bounds.height)
                self.canvasView.drawing.append(strokes)
            case .failure(let error):
                print("Error: \(error)")
            }
        }
        
    }
    
    @IBAction func toggleFingerOrPencil(_ sender: Any){
        if(canvasView.drawingPolicy == PKCanvasViewDrawingPolicy.anyInput){
            canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.pencilOnly
            pencilFingerButton.setTitle("Finger", for: UIControl.State.normal)
        }else{
            canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.anyInput
            pencilFingerButton.setTitle("Pencil", for: UIControl.State.normal)
        }
        
    }
    
    //ViewController Callbacks
    func scrollViewDidZoom(_ scrollView: UIScrollView){
        updateContentSizeForDrawing()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print(abs(canvasView.zoomScale - 1))
        if(abs(canvasView.zoomScale - 1) < 0.2){
            canvasView.setZoomScale(1.0, animated: true)
        }
        updateContentSizeForDrawing(animated:true)
    }
    
    
    
    //CanvasPage Helpers
    func addPage(){
        canvasOverscrollHeight += pageHeight
        updateContentSizeForDrawing()
    }
    
    func redrawPageBreaks(){
        pageBreakLayer.removeFromSuperlayer()
        pageBreakLayer = CAShapeLayer()
        
        let pageBreakPath = UIBezierPath()
        for lineY in stride(from: pageHeight, to: canvasOverscrollHeight, by: pageHeight) {
            pageBreakPath.move(to: CGPoint(x: 0, y: lineY * canvasView.zoomScale))
            pageBreakPath.addLine(to: CGPoint(x: pageWidth * canvasView.maximumZoomScale, y: lineY * canvasView.zoomScale))
            pageBreakPath.lineWidth = 3.0
            pageBreakPath.stroke()
        }
        
        pageBreakLayer.path = pageBreakPath.cgPath
        pageBreakLayer.strokeColor = UIColor(hex: "#dccfbc").cgColor
        pageBreakLayer.lineWidth = 3.0
        
        let pageRect = UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageWidth * canvasView.zoomScale, height: canvasOverscrollHeight * canvasView.zoomScale))
        pageLayer.path = pageRect.cgPath
        pageLayer.fillColor = UIColor.white.cgColor

        canvasView.layer.insertSublayer(pageBreakLayer, at: 0)
        pageLayer.zPosition = 0
        canvasView.layer.insertSublayer(pageLayer, at: 0)
        
        var contentHeight: CGFloat
        var contentWidth: CGFloat
        if !canvasView.drawing.bounds.isNull{
            contentWidth = pageWidth * canvasView.zoomScale
            contentHeight = self.canvasOverscrollHeight * canvasView.zoomScale
            
        }else{
            contentWidth = canvasView.bounds.width
            contentHeight = canvasView.bounds.height
        }
    }
    
    func updateContentSizeForDrawing(animated: Bool = false){
        let drawing = canvasView.drawing
        var contentHeight: CGFloat
        var contentWidth: CGFloat
        
        if !drawing.bounds.isNull{
            contentWidth = pageWidth * canvasView.zoomScale
            contentHeight = self.canvasOverscrollHeight * canvasView.zoomScale
            
        }else{
            contentWidth = canvasView.bounds.width
            contentHeight = canvasView.bounds.height
        }
        
        canvasView.contentSize = CGSize(width: contentWidth, height: contentHeight)
        let contentOffset = max(0, (canvasView.bounds.width - contentWidth)/2)
        if(canvasView.zoomScale < 1){
            canvasView.setContentOffset(CGPoint(x: -contentOffset, y:0), animated: animated)
            canvasView.contentInset = UIEdgeInsets(top: 0, left: contentOffset, bottom: 0, right: 0)
        }else if(canvasView.zoomScale == 1){
            canvasView.setContentOffset(CGPoint(x: 0, y:0), animated: animated)
            canvasView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        redrawPageBreaks()
    }
    
    func getLassoSelection() -> (PKDrawing, CGPoint){
       // Assuming the lasso tool has made a selection at this point
       // Make a backup of the current PKCanvasView drawing state
       let currentDrawingStrokes = canvasView.drawing.strokes
       
       // Issue a delete command so the selected strokes are deleted
       UIApplication.shared.sendAction(#selector(delete), to: nil, from: self, for: nil)
       
       // Store the drawing with the selected strokes removed
       let unselectedStrokes = canvasView.drawing.strokes
        
        // Put the original strokes back in the PKCanvasView
       canvasView.drawing.strokes = currentDrawingStrokes
        
        var selectedStrokes: [PencilKit.PKStroke] = []
        for currentStroke in currentDrawingStrokes{
            if !unselectedStrokes.contains(currentStroke){
                selectedStrokes.append(currentStroke)
            }
        }
        
        var minX = view.bounds.width
        var minY = view.bounds.height
        var maxX = 0.0
        var maxY = 0.0
        
        for selectedStroke in selectedStrokes{
            let bounds = selectedStroke.renderBounds
            if bounds.origin.x < minX {
                minX = bounds.origin.x
            }
            if bounds.origin.x + bounds.width > maxX {
                maxX = bounds.origin.x + bounds.width
            }
            if bounds.origin.y < minY {
                minY = bounds.origin.y
            }
            if bounds.origin.y + bounds.height > maxY {
                maxY = bounds.origin.y + bounds.height
            }
        }
        
        let selectionBounds = CGRect(x: minX, y: minY, width:maxX - minX, height: maxY - minY) //idk about this
        let drawing = PKDrawing(strokes: selectedStrokes)
        
        let y_offset = minY
        let placmentPoint = CGPoint(x : maxX, y: y_offset)
        
        return (drawing, placmentPoint)
   }
    
    func drawCircle(_ point: CGPoint){
        let circlePath = UIBezierPath(arcCenter: point, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        
        let strokes = BezierToStroke(path: circlePath)
        canvasView.drawing.append(strokes)
    }
    
    
}

