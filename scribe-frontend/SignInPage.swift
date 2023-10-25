//
//  SignInPage.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/24/23.
//

import UIKit
import GoogleSignIn

class SignInPage: UIViewController{
    
    
    override func viewDidLoad(){

    }
    
    override func viewDidLayoutSubviews(){

    }
    
    //Delegate Callbacks
    override func viewDidAppear(_ animated: Bool) {

    }
    
    
    //Button Callbacks
    @IBAction func signIn(_ sender: GIDSignInButton) {
        print("sign in")
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
          guard error == nil else { return }
            // If sign in succeeded, display the app's main content View.
            
            let email =  GIDSignIn.sharedInstance.currentUser?.profile?.email
            
            checkIfAuthorizedEmail(email: email!) { result in
                if let result = result {
                    if result {
                        print("Email authorized")
                        let destinationViewController = self.storyboard?.instantiateViewController(withIdentifier: "HomePage")
                        destinationViewController!.navigationItem.hidesBackButton = true
                        self.navigationController?.pushViewController(destinationViewController!, animated: true)
                    }else{
                        let alert = UIAlertController(title: "Unauthorized Email", message: "Scribe is not yet available to the public. To access Scribe please add yourself to the waitlist at use-scribe.co and we will be in contact with you shortly.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                } else {
                    print("Cant connect to backend")
                    let alert = UIAlertController(title: "Unable to Check Waitlist Status", message: "Sorry we are currently unable to check your status on the waitlist. Please try again later", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    //Helpers
    
    
}

