//
//  FileUtils.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/21/23.
//

import Foundation
import PencilKit
import QuickLook
import QuickLookThumbnailing

func saveFile(path: String, data: Data) {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let filePath = documentsDirectory.appendingPathComponent(path)
        do {
            // Ensure the directory structure exists
            let directory = filePath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            
            // Write the SVG content to the file
            try data.write(to: filePath, options: .atomic)
//            print("New file saved at: \(filePath.path)")
            
        } catch {
            print("Error writing data content to file: \(error)")
        }
    } else {
        print("Unable to access the documents directory.")
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

func getDefaultUnitledNotePath() -> URL {
    let baseName = "Untitled Note"
    let fileManager = FileManager.default
    var count = 1
    
    while true {
        let fileName:String
        if count == 1{
            fileName = "\(baseName)"
        }else{
            fileName = "\(baseName) \(count)"
        }
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileUrl = documentsDirectory.appendingPathComponent("Notes/\(fileName).scrib")
            
            if !fileManager.fileExists(atPath: fileUrl.path) {
                return fileUrl
            }
            count += 1
        }
    }
}

//func renameFile(at originalURL: URL, to newFileName: String) -> URL? {
//    print("at", originalURL.path)
//    print("to", newFileName)
//    let fileManager = FileManager.default
//
//    do {
//        // Construct the destination URL with the new file name
//        let destinationURL = originalURL.deletingLastPathComponent().appendingPathComponent(newFileName)
//        print("destinationURL", destinationURL)
//        // Rename the file
//        try fileManager.moveItem(at: originalURL, to: destinationURL)
//
//        print("File renamed successfully.")
//        return destinationURL
//    } catch {
//        print("Error renaming the file: \(error)")
//        return nil
//    }
//}

func renameFile(at: String, to: String) -> URL? {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let originalURL = documentsDirectory.appendingPathComponent(at)
        print("originalURL", originalURL)
                // Rename the file
        let destinationURL = originalURL.deletingLastPathComponent().appendingPathComponent(to)
        print("destinationURL",destinationURL)
        do{
            try FileManager.default.moveItem(at: originalURL, to: destinationURL)
        
                print("File renamed successfully.")
                return destinationURL
        } catch {
            print("Error renaming the file: \(error)")
            return nil
        }
    } else {
        print("Unable to access the documents directory.")
    }
    return nil
}

func createFolderIfDoesntExist(_ name:String) {
    let fileManager = FileManager.default
    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        let folderURL = documentsDirectory.appendingPathComponent(name)
        
        // Check if the "exports" folder exists, and if not, create it.
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("Created 'exports' folder at \(folderURL.path)")
            } catch {
                print("Error creating 'exports' folder: \(error.localizedDescription)")
            }
        } else {
            print("'exports' folder already exists at \(folderURL.path)")
        }
    }
}

func folderExists(atPath path: String) -> Bool {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    
    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        let folderURL = documentsDirectory.appendingPathComponent(path)
        
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        } else {
            return false
        }
    }
    return false
}

import UIKit
import QuickLookThumbnailing

class ScribeThumbnailProvider: QLThumbnailProvider {
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // Use the fileURL directly from the request
        let fileURL = request.fileURL
        
        // Load the drawing from the .scribe file
        if let drawing = openDrawingFromURL(fileURL) {
            
            // Generate the thumbnail using the drawing's image() function
            let thumbnailImage = drawing.image(from: CGRect(x: 0, y: 0, width: 1024, height: 1366), scale: 1) // Adjust this according to your drawing object's API
            
            // Draw the thumbnail into the current context
            handler(QLThumbnailReply(contextSize: request.maximumSize, currentContextDrawing: { () -> Bool in
                // Draw the thumbnail image
                thumbnailImage.draw(in: CGRect(origin: .zero, size: request.maximumSize))
                
                // Return true if the thumbnail was successfully drawn
                return true
            }), nil)
            
        } else {
            // Handle error loading the drawing
            handler(nil, NSError(domain: "com.example.app", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error loading drawing"]))
        }
    }
    
}
