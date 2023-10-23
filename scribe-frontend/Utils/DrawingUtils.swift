//
//  DrawingUtils.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/22/23.
//

import Foundation
import PencilKit

//func saveDrawingAsPDF(drawing: PKDrawing, pdfURL: URL, pageWidth: CGFloat, pageHeight: CGFloat, fullHeight: CGFloat) {
//    // Create a PDF context
//    UIGraphicsBeginPDFContextToFile(pdfURL.path, CGRect.zero, nil)
//    
//    for pageIndex in 1...Int(round(fullHeight / pageHeight)) {
//        // Start a new page in the PDF
//        UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil) // Standard US Letter size
//
//        // Render the drawing on the current page
//        let image = drawing.image(from: drawing.bounds, scale: 1.0)
//        image.draw(at: CGPoint(x: 0, y: 0))
//        
//        // Optionally, you can add a page number or title to each page
//        let pageInfo = "Page \(pageIndex + 1)"
//        pageInfo.draw(at: CGPoint(x: 20, y: 20), withAttributes: nil)
//    }
//    
//    // Finish and save the PDF
//    UIGraphicsEndPDFContext()
//    
//    print("PDF saved at: \(pdfURL.path)")
//}

//func saveDrawingAsPDF(drawing: PKDrawing, pdfURL: URL) {
//    let image = drawing.image(from: drawing.bounds, scale: 1.0)
//
//    // Create a PDF context
//    UIGraphicsBeginPDFContextToFile(pdfURL.path, CGRect.zero, nil)
//
//    // Start a new page in the PDF
//    UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height), nil)
//
//    // Draw the image on the PDF page
//    image.draw(at: CGPoint(x: 0, y: 0))
//
//    // Finish and save the PDF
//    UIGraphicsEndPDFContext()
//
//    print("PDF saved at: \(pdfURL.path)")
//}

func createFileURLInDocumentsDirectory(fileName: String) -> URL {
    if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        return documentsURL.appendingPathComponent(fileName)
    } else {
        fatalError("Could not get the Documents directory URL.")
    }
}
