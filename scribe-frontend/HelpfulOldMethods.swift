//
//  HelpfulOldMethods.swift
//  Sciber
//
//  Created by Ty Todd on 10/1/23.
//

import PencilKit
import UIKit
import SwiftDraw
import PocketSVG

let canvasView: PKCanvasView = {
    let canvas = PKCanvasView()
    canvas.drawingPolicy = .anyInput
    return canvas
}()

//func placeImage(selectionImage:UIImage){
//        var (selectionImage, placementPoint) = LassoToUIImage()
//        let imageView = UIImageView(image: selectionImage)
//        placementPoint.y = placementPoint.y - imageView.center.y
//        imageView.frame = CGRect(origin: placementPoint, size: selectionImage.size)
//        view.addSubview(imageView)
//        drawCircle(point: placementPoint)
//
//}

//func drawSVG(){
//    let svgURL = Bundle.main.url(forResource: "3", withExtension: "svg")!
//    let paths = SVGBezierPath.pathsFromSVG(at: svgURL)
//    let origin = paths[0].bounds.origin
//    print(paths[0].bounds)
//    paths[0].apply(CGAffineTransform(translationX: -origin.x, y: -origin.y))
//    paths[0].apply(CGAffineTransform(scaleX: 0.01, y: 0.01))
//    let shapeLayer = CAShapeLayer()
//    shapeLayer.path = paths[0].cgPath
//   // Change the fill color
//    shapeLayer.fillColor = UIColor.clear.cgColor
//    // You can change the stroke color
//    shapeLayer.strokeColor = UIColor.red.cgColor
//   // You can change the line width
//    shapeLayer.lineWidth = 3.0
//    canvasView.layer.addSublayer(shapeLayer)
//}

//func LassoToUIImage() -> (UIImage, CGPoint){
//   // Assuming the lasso tool has made a selection at this point
//   // Make a backup of the current PKCanvasView drawing state
//   let currentDrawingStrokes = canvasView.drawing.strokes
//
//   // Issue a delete command so the selected strokes are deleted
////   UIApplication.shared.sendAction(#selector(delete), to: nil, from: self, for: nil)
//
////       // Store the drawing with the selected strokes removed
//   let unselectedStrokes = canvasView.drawing.strokes
////        print((currentDrawingStrokes, unselectedStrokes))
////
////       // Put the original strokes back in the PKCanvasView
//   canvasView.drawing.strokes = currentDrawingStrokes
//
//    var selectedStrokes: [PencilKit.PKStroke] = []
////        print("new")
//    for currentStroke in currentDrawingStrokes{
//        if !unselectedStrokes.contains(currentStroke){
//            selectedStrokes.append(currentStroke)
//        }
//    }
//
//    var minX = view.bounds.width
//    var minY = view.bounds.height
//    var maxX = 0.0
//    var maxY = 0.0
//
//    for selectedStroke in selectedStrokes{
//        let bounds = selectedStroke.renderBounds
//        if bounds.origin.x < minX {
//            minX = bounds.origin.x
//        }
//        if bounds.origin.x + bounds.width > maxX {
//            maxX = bounds.origin.x + bounds.width
//        }
//        if bounds.origin.y < minY {
//            minY = bounds.origin.y
//        }
//        if bounds.origin.y + bounds.height > maxY {
//            maxY = bounds.origin.y + bounds.height
//        }
//    }
//
//    let selectionBounds = CGRect(x: minX, y: minY, width:maxX - minX, height: maxY - minY) //idk about this
//    let drawing = PKDrawing(strokes: selectedStrokes)
//    let selectionImage = drawing.image(from:selectionBounds, scale:1)
//
//    let y_offset = (minY + maxY)/2.0 + 300
//    let placmentPoint = CGPoint(x : maxX, y: y_offset)
//
//    return (selectionImage, placmentPoint)
//}

func drawCircle(point: CGPoint){
    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 100,y:100), radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
    circlePath.append(UIBezierPath(arcCenter: CGPoint(x: 200, y:200), radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true))
    
    let strokes = BezierToStroke(path: circlePath)
//        print(drawing.strokes)
    canvasView.drawing.append(strokes)
//        canvasView.drawing = drawing
//        print(drawing.strokes[0])
//        drawing = drawing.appending(circleDrawing)
    
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.path = circlePath.cgPath
////
////        // Change the fill color
//        shapeLayer.fillColor = UIColor.clear.cgColor
////        // You can change the stroke color
//        shapeLayer.strokeColor = UIColor.red.cgColor
////        // You can change the line width
//        shapeLayer.lineWidth = 3.0
//////        drawing =
//        canvasView.layer.addSublayer(shapeLayer)
}
