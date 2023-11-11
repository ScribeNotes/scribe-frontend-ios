//
//  ThumbnailProvider.swift
//  Thumbnail
//
//  Created by Ty Todd on 11/10/23.
//

import UIKit
import QuickLookThumbnailing
import PencilKit


class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        print("Thumbnail request received for \(request.fileURL)")
        let pageAspectRatio:CGFloat = 8.5/11
        
        let pageWidth = 820
        let pageHeight = Int(1/pageAspectRatio * CGFloat(pageWidth))
        print("pageHeight", pageHeight)
        
        let desiredHeight = request.maximumSize.height
        let desiredWidth = desiredHeight * pageAspectRatio
        let desiredSize = CGSize(width: desiredWidth, height: desiredHeight)
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
        let fileURL = request.fileURL
        if let drawing = openDrawingFromURL(fileURL) {
            let thumbnailImage = drawing.image(from: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), scale: 1)
            handler(QLThumbnailReply(contextSize: desiredSize, currentContextDrawing: { () -> Bool in
                // Draw the thumbnail here.
                thumbnailImage.draw(in: CGRect(origin: .zero, size: desiredSize))
                // Return true if the thumbnail was successfully drawn inside this block.
                return true
            }), nil)
        }
        
        /*
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
         
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
         */
        
        // Third way: Set an image file URL.
//        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "Scribe_Launch_Screen", withExtension: "png")!), nil)
        
//        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "test", withExtension: "png")!), nil)
        
    }
}

func openDrawingFromURL(_ url: URL) -> PKDrawing? {
    do {
        let data = try Data(contentsOf: url)
        let drawing = try PKDrawing(data: data)
        print("drawing opened at", url.path)
        return drawing
    } catch {
        print("Error reading data from URL: \(error)")
        return nil
    }
}

