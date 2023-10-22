//
//  FileUtils.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/21/23.
//

import Foundation
import PencilKit

func saveFile(path: String, data: Data) {
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let filePath = documentsDirectory.appendingPathComponent(path)
        do {
            // Ensure the directory structure exists
            let directory = filePath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            
            // Write the SVG content to the file
            try data.write(to: filePath, options: .atomic)
                print("New file saved at: \(filePath.path)")
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
        return drawing
    } catch {
        print("Error reading data from URL: \(error)")
        return nil
    }
}
