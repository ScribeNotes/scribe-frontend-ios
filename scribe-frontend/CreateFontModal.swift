//
//  CreateFontModal.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/25/23.
//

import Foundation

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



class CreateFontModal: UIViewController, PKCanvasViewDelegate,UITextFieldDelegate {
    
    //Modal
    @IBOutlet weak var modalView: UIView!
    
    //Boxes
    @IBOutlet var box1: UIView!
    @IBOutlet var box2: UIView!
    @IBOutlet var box3: UIView!
    
    //Labels and Buttons
    @IBOutlet var charLabels: [UILabel]!
    @IBOutlet var nextButton: UIButton!
    
    let charsToDraw:[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", ".", ",", "x", "y"]
    var currIndex = 0
    
    //Canvas Views
    private let canvasView1: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()
    
    private let canvasView2: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()

    private let canvasView3: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()
    
    let toolPicker = PKToolPicker()
    override func viewDidLoad(){
        super.viewDidLoad()
        
        //Modal setup
        modalView.layer.shadowColor = UIColor.black.cgColor
        modalView.layer.shadowOpacity = 0.5
        modalView.layer.shadowOffset = CGSize(width: 2, height: 2)
        modalView.layer.shadowRadius = 4
        modalView.layer.masksToBounds = false
        
        //Setup canvas Views
        canvasView1.drawing = PKDrawing()
        canvasView1.delegate = self
        canvasView1.backgroundColor = UIColor.clear
        box1.addSubview(canvasView1)
        canvasView1.frame = box1.bounds
        
        canvasView2.drawing = PKDrawing()
        canvasView2.delegate = self
        canvasView2.backgroundColor = UIColor.clear
        box2.addSubview(canvasView2)
        canvasView2.frame = box1.bounds
//
        canvasView3.drawing = PKDrawing()
        canvasView3.delegate = self
        canvasView3.backgroundColor = UIColor.clear
        box3.addSubview(canvasView3)
        canvasView3.frame = box1.bounds
        
        //Labels setup
        for charLabel in charLabels{
            charLabel.text = charsToDraw[0]
        }
        
        let selectedTool = PKInkingTool(.pen, color: .black, width: 10.0)
        toolPicker.selectedTool = selectedTool
    }
    
    override func viewDidLayoutSubviews(){
//        super.viewDidLayoutSubviews()
//        canvasView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView1)
        toolPicker.addObserver(canvasView1)
        toolPicker.addObserver(canvasView2)
        toolPicker.addObserver(canvasView3)
//        canvasView1.becomeFirstResponder()
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print("drawing updated")
    }
    
    

    @IBAction func redoButtonPressed(_ sender: Any) {
        
        let targetObject = canvasView1

        if targetObject.undoManager!.canRedo {
            // Perform the undo action
            targetObject.undoManager!.redo()
        }
    }
    
    @IBAction func undoButtonPressed(_ sender: Any) {
        let targetObject = canvasView1

        if targetObject.undoManager!.canUndo {
            // Perform the undo action
            targetObject.undoManager!.undo()
        }
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        print("next")
        let canvasViews = [canvasView1, canvasView2, canvasView3]
        for canvasView in canvasViews{
            let svg = PKDrawingToSVG(drawing: canvasView.drawing)
            saveCustomFontFile(svgContent: svg, char: charsToDraw[currIndex].first!)
            canvasView.drawing = PKDrawing()
        }
        print("saved")
        
        if currIndex >= charsToDraw.count-1{
            dismiss(animated: true, completion: nil)
            return
        }
        currIndex += 1
        
        for charLabel in charLabels{
            charLabel.text = charsToDraw[currIndex]
        }
        
        if currIndex == charsToDraw.count - 1{
            nextButton.setTitle("Done", for: .normal)
        }
        
        
        
    }
    
    
    

    
//    @IBAction func saveCharachter(_ sender: Any) {
//        var (selectionDrawing, placementPoint) = getLassoSelection()
//        let svg = PKDrawingToSVG(drawing: selectionDrawing)
//
//        saveCustomFontFile(svgContent: svg, char: currChar)
//        print("saved")
//
//    }
    
    func saveCustomFontFile(svgContent: String, char: Character) {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let asciiValue = char.unicodeScalars.first?.value {
                print("ASCII value of \(char) is \(asciiValue)")
                let filePath = documentsDirectory.appendingPathComponent("/myfont_svg/\(asciiValue)/\(randomString(length: 5)).svg")
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
                print("Couldn't retrieve ASCII value for the character.")
            }
        } else {
            print("Unable to access the documents directory.")
        }
    }
//
//    func saveSVG(svgContent: String, name:String){
//        let fileManager = FileManager.default
//        if let data = svgContent.data(using: .utf8) {
//            let success = fileManager.createFile(atPath: "3.svg", contents: data, attributes: nil)
//            if success {
//                print("File created and data written successfully.")
//            } else {
//                print("Failed to create file.")
//            }
//        } else {
//            print("Failed to convert string to data.")
//        }
//
//    }
//
//
//    func getLassoSelection() -> (PKDrawing, CGPoint){
//       // Assuming the lasso tool has made a selection at this point
//       // Make a backup of the current PKCanvasView drawing state
//       let currentDrawingStrokes = canvasView.drawing.strokes
//
//       // Issue a delete command so the selected strokes are deleted
//       UIApplication.shared.sendAction(#selector(delete), to: nil, from: self, for: nil)
//
////       // Store the drawing with the selected strokes removed
//       let unselectedStrokes = canvasView.drawing.strokes
////
////       // Put the original strokes back in the PKCanvasView
//       canvasView.drawing.strokes = currentDrawingStrokes
//
//        var selectedStrokes: [PencilKit.PKStroke] = []
//        for currentStroke in currentDrawingStrokes{
//            if !unselectedStrokes.contains(currentStroke){
//                selectedStrokes.append(currentStroke)
//            }
//        }
//
//        var minX = view.bounds.width
//        var minY = view.bounds.height
//        var maxX = 0.0
//        var maxY = 0.0
//
//        for selectedStroke in selectedStrokes{
//            let bounds = selectedStroke.renderBounds
//            if bounds.origin.x < minX {
//                minX = bounds.origin.x
//            }
//            if bounds.origin.x + bounds.width > maxX {
//                maxX = bounds.origin.x + bounds.width
//            }
//            if bounds.origin.y < minY {
//                minY = bounds.origin.y
//            }
//            if bounds.origin.y + bounds.height > maxY {
//                maxY = bounds.origin.y + bounds.height
//            }
//        }
//
//        let selectionBounds = CGRect(x: minX, y: minY, width:maxX - minX, height: maxY - minY) //idk about this
//        let drawing = PKDrawing(strokes: selectedStrokes)
//
//        let y_offset = minY//(minY + maxY)/2.0
//        let placmentPoint = CGPoint(x : maxX, y: y_offset)
//
//        return (drawing, placmentPoint)
//   }
//
//    func drawCircle(_ point: CGPoint){
//        let circlePath = UIBezierPath(arcCenter: point, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
//
//        let strokes = BezierToStroke(path: circlePath)
//        canvasView.drawing.append(strokes)
//    }
//
//
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        toolPicker.setVisible(true, forFirstResponder: canvasView)
//        canvasView.becomeFirstResponder()
//
//        return true
//    }
//
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
//
//

    
}


