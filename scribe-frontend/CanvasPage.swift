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

class CanvasPage: UIViewController, PKCanvasViewDelegate,UITextFieldDelegate {
    
//    let drawing = BezierToStroke(path: UIBezierPath(arcCenter: CGPoint(x:500,y:500), radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true))
    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()
    let toolPicker = PKToolPicker()
    var drawing = PKDrawing()

    override func viewDidLoad(){
        super.viewDidLoad()
        canvasView.drawing = drawing
        canvasView.delegate = self
        view.addSubview(canvasView)
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        canvasView.frame = CGRect(x: 0, y: 300, width: view.bounds.width, height: view.bounds.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
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
//                print("Response SVG: \(responseSVG)")
                var endTime = DispatchTime.now()
                var nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                var timeInterval = Double(nanoTime) / 1_000_000_000 // Convert to seconds
                print("request time: \(timeInterval) seconds")
                let strokes = SVGtoStroke(svg:responseSVG, placementPoint: placementPoint, ink: selection_ink, samplePoint: sample_point, target_height: selectionDrawing.bounds.height)
                self.canvasView.drawing.append(strokes)
            case .failure(let error):
                print("Error: \(error)")
                // Handle the error here
            }
        }
        
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
        
        let y_offset = minY//(minY + maxY)/2.0
        let placmentPoint = CGPoint(x : maxX, y: y_offset)
        
        return (drawing, placmentPoint)
   }
    
    func drawCircle(_ point: CGPoint){
        let circlePath = UIBezierPath(arcCenter: point, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        
        let strokes = BezierToStroke(path: circlePath)
        canvasView.drawing.append(strokes)
    }
    
    
}

