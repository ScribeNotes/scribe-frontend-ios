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

class CanvasPage: UIViewController, PKCanvasViewDelegate,UITextFieldDelegate, UIDocumentInteractionControllerDelegate {
    
    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .pencilOnly
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
    
    //Zoom Variables
    var startingWidth:CGFloat = 0.0
    var homeZoom:CGFloat = 1.0
    
    //Utilities
    let toolPicker = PKToolPicker()
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var shareButton:UIButton!
    var documentController: UIDocumentInteractionController!

    //File Variables
    var notePath: URL?
    
    //ViewController Setup
    override func viewDidLoad(){
        
        super.viewDidLoad()
        //canvasView setup
        canvasView.drawing = PKDrawing()
        canvasView.delegate = self
        canvasView.bounces = true
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = false
        canvasView.bouncesZoom = true
        canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.pencilOnly
        
        //FIXME hacky way of avoiding errors when there is no drawing on the canvasView
        let dotPoint = PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0.0, size: CGSize(width: 1, height: 1), opacity: 1.0, force: 1.0, azimuth: 0, altitude: 0)
        let dotStroke = PKStroke(ink: PKInk(.pen, color: UIColor.black), path: PKStrokePath(controlPoints:[dotPoint], creationDate: Date()))
        canvasView.drawing.append(PKDrawing(strokes: [dotStroke]))
        
        //Page setup
        pageWidth = view.bounds.width
        pageHeight = 1/pageAspectRatio * pageWidth
        canvasOverscrollHeight = pageHeight
        startingWidth = view.bounds.width
        print("pageHeight",pageHeight)
        print("canvasOverscrollHeight", canvasOverscrollHeight)
        
        // UI Setup
        nameTextField.delegate = self
        navigationController?.navigationBar.backgroundColor = UIColor.white
        
        //View Setup
        view.addSubview(canvasView)
        view.backgroundColor = UIColor(hex: "#dccfbc")
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = true
        
        //Load Note
        print("note path1",notePath)
        if notePath != nil{
            let uploadedDrawing = openDrawingFromURL(notePath!)
            print("uploadedDrawing", uploadedDrawing)
            canvasView.drawing = uploadedDrawing ?? canvasView.drawing
            
            let fileName = notePath!.deletingPathExtension().lastPathComponent
            nameTextField.text = fileName
        }else{
            notePath = getDefaultUnitledNotePath()
            let fileName = notePath!.deletingPathExtension().lastPathComponent
            nameTextField.text = fileName
        }
        print("notePath", notePath)
        adjustNumPages()
        
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        canvasView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        let canvasScale = canvasView.bounds.width / pageWidth
        canvasView.minimumZoomScale = 0.5
        canvasView.maximumZoomScale = 5
        canvasView.zoomScale = canvasScale
        
        if(view.bounds.width != startingWidth){
            homeZoom = 1 * view.bounds.width/startingWidth
            print("new home zoom")
        }else{
            homeZoom = 1
        }
        
        updateContentSizeForDrawing()
        redrawPageBreaks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reshowToolBar()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool{
        return true
    }
    
    
    
    
    
    // Button Callbacks
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.anyInput
            
        } else {
            canvasView.drawingPolicy = PKCanvasViewDrawingPolicy.pencilOnly
        }
    }
        
        
    @IBAction func shareButtonCallback(_ sender: Any) {
        print("share")
        if let window = UIApplication.shared.keyWindow {
            
            let locationInWindow = shareButton.convert(shareButton.frame, to: window)
            let noteName = notePath!.deletingPathExtension().lastPathComponent
            print("noteName",noteName)
            createFolderIfDoesntExist("Exports")
            let url = createFileURLInDocumentsDirectory(fileName: "Exports/\(noteName).pdf")
            saveDrawingAsPDF(pdfURL: url)
            
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [])
            
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.sourceView = self.view
                popoverPresentationController.sourceRect = locationInWindow
            }

            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func evaluate(_ sender: Any) {
        print("evaluate")
        var (selectionDrawing, placementPoint) = getLassoSelection()
        print("placeMent point", placementPoint)
        if selectionDrawing.strokes.count == 0{
            let alert = UIAlertController(title: "No Selection", message: "Please use the lasso tool to select the expression you would like to evaluate", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }

        let selection_ink = selectionDrawing.strokes[0].ink
        let sample_point = selectionDrawing.strokes[0].path[0]
        
        let svg = PKDrawingToSVG(drawing: selectionDrawing)

        var startTime = DispatchTime.now()
        APIEvaluateToText(with: svg) { result in
            switch result {
            case .success(let responseAnswer):
                var endTime = DispatchTime.now()
                var nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                var timeInterval = Double(nanoTime) / 1_000_000_000 // Convert to seconds
                print("request time: \(timeInterval) seconds")
                //keep for working with svgs
//                let strokes = textTo(svg:responseSVG, placementPoint: placementPoint, ink:                                    selection_ink, samplePoint: sample_point, target_height:                                    selectionDrawing.bounds.height)
                let answer = textToHandwriting(text: responseAnswer, placementPoint: placementPoint, ink: selection_ink, samplePoint: sample_point, target_height: selectionDrawing.bounds.height)
                if answer == nil{
                    print("nil answer")
                }else{
                    print("answer", answer)
                }
                self.canvasView.drawing.append(answer!)
                
            case .failure(let error):
                print("Error evaluating: \(error)")
            }
        }
        
        reshowToolBar()
        
    }
    
    @IBAction func saveButtonPressed(_ sender: Any){
        save()
    }
    
    
    //ViewController Callbacks
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView){
        updateContentSizeForDrawing()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if(abs(canvasView.zoomScale - homeZoom) < 0.2){
            canvasView.setZoomScale(homeZoom, animated: true)
        }
        updateContentSizeForDrawing(animated:true)
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        adjustNumPages()
        save()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        updateFileName(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateFileName(textField)
        return true
    }
    
    //CanvasPage Helpers
    func updateFileName(_ textField: UITextField){
        print("text field changed")
        save()
        let basePath = notePath!.deletingLastPathComponent().path
        if basePath != nil {
            if !textField.text!.isEmpty {
                var newFileName = "\(textField.text!).scribe"
                let updatedURL = URL(fileURLWithPath: basePath).appendingPathComponent(newFileName)
                print("Updated URL: \(updatedURL)")
                let newPath = renameFile(at: "Notes/\(notePath!.lastPathComponent)", to: newFileName)
                if newPath == nil{
                    textField.text! = notePath!.deletingPathExtension().lastPathComponent
                }else{
                    notePath = newPath
                }
            }else{
                textField.text! = notePath!.deletingPathExtension().lastPathComponent
            }
        }
        textField.resignFirstResponder()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    func save(){
        if notePath == nil{
            return
        }
        let data:Data
        do {
            data = try canvasView.drawing.dataRepresentation()
        } catch {
            print("Error converting drawing to data: \(error)")
            //FIXME tell user there has been an error
            return
        }
//        print("name", notePath!.lastPathComponent)
        saveFile(path: "Notes/\(notePath!.lastPathComponent)", data: data)
        
    }
    
    func adjustNumPages(){
        if pageHeight == 0{
            return
        }
        let numPages = ceil(canvasView.drawing.bounds.maxY / pageHeight) + 1
        canvasOverscrollHeight = numPages * pageHeight
        updateContentSizeForDrawing()
    }
    
    func redrawPageBreaks(){
        if(pageHeight == 0 || canvasOverscrollHeight == 0 ){
            return
        }
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
        if(canvasView.zoomScale < homeZoom){
            canvasView.setContentOffset(CGPoint(x: -contentOffset, y:canvasView.contentOffset.y), animated: animated)
            canvasView.contentInset = UIEdgeInsets(top: canvasView.contentInset.top, left: contentOffset, bottom: 0, right: 0)
        }else if(canvasView.zoomScale == homeZoom){
            //            canvasView.setContentOffset(CGPoint(x: 0, y:0), animated: animated)
            canvasView.contentInset = UIEdgeInsets(top: canvasView.contentInset.top, left: 0, bottom: 0, right: 0)
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
        
        let drawing = PKDrawing(strokes: selectedStrokes)
        let selectionBounds = drawing.bounds
        let y_offset = selectionBounds.minY //minY
        let placmentPoint = CGPoint(x : selectionBounds.maxX, y: y_offset)
        
        return (drawing, placmentPoint)
    }
    
    func drawCircle(_ point: CGPoint){
        let circlePath = UIBezierPath(arcCenter: point, radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
        
        let strokes = BezierToStroke(path: circlePath)
        canvasView.drawing.append(strokes)
    }
    
    func saveDrawingAsPDF(pdfURL: URL) {
        // Create a PDF context
        UIGraphicsBeginPDFContextToFile(pdfURL.path, CGRect.zero, nil)

        for pageIndex in 1..<Int(floor(canvasOverscrollHeight / pageHeight)) {
            // Start a new page in the PDF
            UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil) // Standard US Letter size

            // Render the drawing on the current page
            let pageBounds = CGRect(x: 0, y: CGFloat(pageIndex-1)*pageHeight, width: pageWidth, height: CGFloat(pageIndex)*pageHeight)
            let image = canvasView.drawing.image(from: pageBounds, scale: 5.0)
            image.draw(at: CGPoint(x: 0, y: 0))
        }

        // Finish and save the PDF
        UIGraphicsEndPDFContext()

        print("PDF saved at: \(pdfURL.path)")
    }
    
    func reshowToolBar(){
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
    }
    
    }

