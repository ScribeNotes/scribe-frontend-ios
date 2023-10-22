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

//extension PKStroke: Equatable {
//    public static func ==(lhs: PKStroke, rhs: PKStroke) -> Bool {
//        return (lhs as PKStrokeReference) === (rhs as PKStrokeReference)
//    }
//}

class ViewController: UIViewController , UIDocumentPickerDelegate{
    
    
    override func viewDidLoad(){

    }
    
    override func viewDidLayoutSubviews(){

    }
    
    //Delegate Callbacks
    override func viewDidAppear(_ animated: Bool) {

    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else {
            return
        }
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var canvasPage = storyboard.instantiateViewController(withIdentifier: "CanvasPage") as? CanvasPage
        canvasPage?.notePath = selectedURL
        print("selectedFile",selectedURL.path)
        
        self.navigationController?.pushViewController(canvasPage!, animated: true)
    }
    
    //Button Callbacks
    @IBAction func openNoteButtonPressed(_ sender: Any){
        openFileExplorer()
    }
    
    //Helpers
    func openFileExplorer() {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let openPath = documentsDirectory.appendingPathComponent("Notes")
            
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.scribe.scribe"], in: .import)
            documentPicker.delegate = self
            documentPicker.directoryURL = openPath
            present(documentPicker, animated: true, completion: nil)
        }
    }
    
    
}

