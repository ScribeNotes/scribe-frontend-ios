//
//  ViewController.swift
//  Scribe
//
//  Created by Ty Todd on 9/16/23.
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

class ViewController: UIViewController, PKCanvasViewDelegate {
    
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
        var (selectionImage, placementPoint) = getLassoSelection()
        
        let strokes = SVGtoStroke()
        canvasView.drawing.append(strokes)
        
        
    }
    
    
    
    func getLassoSelection() -> (UIImage, CGPoint){
       // Assuming the lasso tool has made a selection at this point
       // Make a backup of the current PKCanvasView drawing state
       let currentDrawingStrokes = canvasView.drawing.strokes
       
       // Issue a delete command so the selected strokes are deleted
       UIApplication.shared.sendAction(#selector(delete), to: nil, from: self, for: nil)
       
//       // Store the drawing with the selected strokes removed
       let unselectedStrokes = canvasView.drawing.strokes
//        print((currentDrawingStrokes, unselectedStrokes))
//
//       // Put the original strokes back in the PKCanvasView
       canvasView.drawing.strokes = currentDrawingStrokes
        
        var selectedStrokes: [PencilKit.PKStroke] = []
//        print("new")
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
        let selectionImage = drawing.image(from:selectionBounds, scale:1)
        
        let y_offset = (minY + maxY)/2.0 + 300
        let placmentPoint = CGPoint(x : maxX, y: y_offset)
        
        return (selectionImage, placmentPoint)
   }

    


    
}

