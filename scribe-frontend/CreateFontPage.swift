//
//  CreateFontPage.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/13/23.
//

import PencilKit
import UIKit
import SwiftDraw
import PocketSVG


class CreateFontPage: UIViewController, PKCanvasViewDelegate,UITextFieldDelegate {
    
//    let drawing = BezierToStroke(path: UIBezierPath(arcCenter: CGPoint(x:500,y:500), radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true))
    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()
    let toolPicker = PKToolPicker()
    var drawing = PKDrawing()
    @IBOutlet var fileNameField: UITextField!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        canvasView.drawing = drawing
        canvasView.delegate = self
        view.addSubview(canvasView)
        fileNameField.delegate = self
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        canvasView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }


    
    @IBAction func saveCharachter(_ sender: Any) {
        var (selectionDrawing, placementPoint) = getLassoSelection()
        let svg = PKDrawingToSVG(drawing: selectionDrawing)
        
//        saveSVG(svgContent: svg, name: fileNameField.text!)
        saveCustomFontFile(svgContent: svg, charCode: fileNameField.text!)
        print("saved")
        
    }
    
    func saveCustomFontFile(svgContent: String, charCode: String) {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = documentsDirectory.appendingPathComponent("/myfont_svg/\(charCode)/\(randomString(length: 5)).svg")
            do {
                // Ensure the directory structure exists
                let directory = filePath.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                
                // Write the SVG content to the file
                if let data = svgContent.data(using: .utf8) {
                    try data.write(to: filePath, options: .atomic)
//                    print("SVG content written to file: \(filePath.path)")
                } else {
                    print("Failed to convert SVG content to data.")
                }
            } catch {
                print("Error writing SVG content to file: \(error)")
            }
        } else {
            print("Unable to access the documents directory.")
        }
    }
    
    func saveSVG(svgContent: String, name:String){
        let fileManager = FileManager.default
        if let data = svgContent.data(using: .utf8) {
            let success = fileManager.createFile(atPath: "3.svg", contents: data, attributes: nil)
            if success {
                print("File created and data written successfully.")
            } else {
                print("Failed to create file.")
            }
        } else {
            print("Failed to convert string to data.")
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
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        
        return true
    }

    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""
        
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<letters.count)
            let character = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
            randomString.append(character)
        }
        
        return randomString
    }
    


    
}


