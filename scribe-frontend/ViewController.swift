//
//  ViewController.swift
//  Scribe
//
//  Created by Ty Todd on 9/16/23.
//
import UIKit
import GoogleSignIn

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

class ViewController: UIViewController , UIDocumentPickerDelegate{
    //Utilities
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    
    
    
    override func viewDidLoad(){
        if let user = GIDSignIn.sharedInstance.currentUser{
            print("non nil user")
            userNameLabel.text = user.profile?.name
            let imageURL = user.profile?.imageURL(withDimension: 100)
            if imageURL != nil{
                profileImage.load(url: imageURL!)
            }
        }else{
            print("nil user")
        }
        
        openFontModalIfNoFont()
        
        
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
    
    
    @IBAction func openNoteButtonPressed(_ sender: Any){
        openFileExplorer()
    }
    
    @IBAction func signOutButtonPressed(_ sender: Any){
        GIDSignIn.sharedInstance.signOut()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var signInPage = storyboard.instantiateViewController(withIdentifier: "SignInPage") as? SignInPage
        signInPage?.navigationItem.hidesBackButton = true
        
        self.navigationController?.pushViewController(signInPage!, animated: true)
        
    }
    
    //Helpers
    func openFileExplorer() {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let openPath = documentsDirectory.appendingPathComponent("Notes")
            
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.scribe.scrib"], in: .import)
            documentPicker.delegate = self
            documentPicker.directoryURL = openPath
            present(documentPicker, animated: true, completion: nil)
        }
    }
    
    func openFontModalIfNoFont(){
        print("open if no font")
        if !folderExists(atPath: "myfont_svg"){
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let createFont = storyboard.instantiateViewController(withIdentifier: "CreateFont")
            createFont.modalPresentationStyle = .overCurrentContext
            present(createFont, animated:true)
        }
    }
}

