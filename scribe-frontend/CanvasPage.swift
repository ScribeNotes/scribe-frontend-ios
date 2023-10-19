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
    //scroll variables
    let pageAspectRatio = 8.5/11
    var pageWidth: CGFloat = 0 //set in viewDidLoad
    var pageHeight:CGFloat = 0 //set in viewDidLoad
    var canvasOverscrollHeight: CGFloat = 0 //set in viewDidLoad
    var pageBreakLayer: CAShapeLayer = CAShapeLayer()
    
    //tool picker
    let toolPicker = PKToolPicker()
    
    @IBOutlet weak var pencilFingerButton: UIButton!
    
    
    //ViewController Setup
    override func viewDidLoad(){
        
        super.viewDidLoad()
        //canvasView setup
        canvasView.drawing = PKDrawing()
        canvasView.delegate = self
        canvasView.alwaysBounceVertical = true
        canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.anyInput
        
        //Page setup
        pageWidth = view.bounds.width
        pageHeight = 1/pageAspectRatio * pageWidth
        canvasOverscrollHeight = pageHeight
        
        // UI Setup
        pencilFingerButton.setTitle("Pencil", for: UIControl.State.normal)
        
        //View Setup
        view.addSubview(canvasView)
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        canvasView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        let canvasScale = canvasView.bounds.width / pageWidth
        canvasView.minimumZoomScale = 0.1
        canvasView.maximumZoomScale = 10
        canvasView.zoomScale = canvasScale
        updateContentSizeForDrawing()
        redrawPageBreaks()
//        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
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
        print("toggle")
        if(canvasView.drawingPolicy == PKCanvasViewDrawingPolicy.anyInput){
            canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.pencilOnly
            pencilFingerButton.setTitle("Finger", for: UIControl.State.normal)
        }else{
            canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.anyInput
            pencilFingerButton.setTitle("Pencil", for: UIControl.State.normal)
        }
        
    }
    
    //ViewController Callbacks
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
//        updateContentSizeForDrawing()
    }
    
    //CanvasPage Helpers
    func addPage(){
        canvasOverscrollHeight += pageHeight
        updateContentSizeForDrawing()
        redrawPageBreaks()
    }
    
    func redrawPageBreaks(){
        pageBreakLayer.removeFromSuperlayer()
        pageBreakLayer = CAShapeLayer()
        let pageBreakPath = UIBezierPath()
        for lineY in stride(from: pageHeight, to: canvasOverscrollHeight, by: pageHeight) {
            print(lineY)
            pageBreakPath.move(to: CGPoint(x: 0, y: lineY * canvasView.zoomScale))
            pageBreakPath.addLine(to: CGPoint(x: pageWidth * canvasView.maximumZoomScale, y: lineY * canvasView.zoomScale))
            pageBreakPath.lineWidth = 3.0
            pageBreakPath.stroke()
        }
        pageBreakLayer.path = pageBreakPath.cgPath
        pageBreakLayer.strokeColor = UIColor.red.cgColor
        pageBreakLayer.lineWidth = 3.0
        canvasView.layer.addSublayer(pageBreakLayer)
    }
    
    func updateContentSizeForDrawing(){ //scroll
        let drawing = canvasView.drawing
        var contentHeight: CGFloat
        var contentWidth: CGFloat
        
        if !drawing.bounds.isNull{
            contentWidth = pageWidth * canvasView.zoomScale
            contentHeight = self.canvasOverscrollHeight * canvasView.zoomScale
            
        }else{
            print("else")
            contentWidth = canvasView.bounds.width
            contentHeight = canvasView.bounds.height
        }
        
        
        canvasView.contentSize = CGSize(width: contentWidth, height: contentHeight)
    }
    
    func getLassoSelection() -> (PKDrawing, CGPoint){
       // Assuming the lasso tool has made a selection at this point
       // Make a backup of the current PKCanvasView drawing state
       let currentDrawingStrokes = canvasView.drawing.strokes
       
       // Issue a delete command so the selected strokes are deleted
       UIApplication.shared.sendAction(#selector(delete), to: nil, from: self, for: nil)
       
//       // Store the drawing with the selected strokes removed
       let unselectedStrokes = canvasView.drawing.strokes
//
//       // Put the original strokes back in the PKCanvasView
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

