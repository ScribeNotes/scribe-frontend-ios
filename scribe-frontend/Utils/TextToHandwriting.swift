//
//  TextToHandwriting.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/22/23.
//

import Foundation
import PencilKit

func getCharDrawing(character: Character,
                placementPoint: CGPoint,
                ink: PKInk = PKInk(.pen, color: UIColor.black),
                samplePoint: PKStrokePoint = PKStrokePoint(
                    location: CGPoint(x: 0, y: 0),
                    timeOffset: 0,
                    size: .init(width: 2, height: 2),
                    opacity: 1,
                    force: 0.5,
                    azimuth: 0,
                    altitude: 0),
                target_height: CGFloat = 100) -> PKDrawing? {
    let characterCode = Int(character.asciiValue!)
    let folderPath = "myfont_svg/\(characterCode)"
    
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
    
        let folderURL = documentsDirectory.appendingPathComponent(folderPath)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [])
            
            if contents.isEmpty {
                print("No files found in folder \(folderPath).")
                return nil
            }
            
            let randomIndex = Int.random(in: 0..<contents.count)
            return SVGFiletoStroke(at: contents[randomIndex], placementPoint: placementPoint, ink: ink, samplePoint: samplePoint, target_height: target_height)
        } catch {
            print("Error accessing folder \(folderPath): \(error)")
            return nil
        }
    }
    return nil
}

func textToHandwriting(text:String,
                       placementPoint: CGPoint,
                       ink: PKInk = PKInk(.pen, color: UIColor.black),
                       samplePoint: PKStrokePoint = PKStrokePoint(
                           location: CGPoint(x: 0, y: 0),
                           timeOffset: 0,
                           size: .init(width: 2, height: 2),
                           opacity: 1,
                           force: 0.5,
                           azimuth: 0,
                           altitude: 0),
                       target_height: CGFloat = 100) -> PKDrawing?{
    var result = PKDrawing()
    var currX = placementPoint.x
    for char in text{
        var currY = placementPoint.y
        var currHeight = target_height
        //check for periods and commas
        if char == "." || char == ","{
            let new_height = target_height/10
            currY = placementPoint.y + target_height - new_height/2
            currHeight = new_height
        }
        
        if char == "-"{
            let new_height = target_height/50
            currY = placementPoint.y + target_height/2
            currHeight = new_height
        }
        
        if let writtenChar = getCharDrawing(character: char, placementPoint: CGPoint(x: currX, y: currY), ink:ink, samplePoint: samplePoint, target_height: currHeight) {
            result.append(writtenChar)
            currX = writtenChar.bounds.maxX + 10
        }
        else{
            return nil
        }
        
    }
    return result
}


