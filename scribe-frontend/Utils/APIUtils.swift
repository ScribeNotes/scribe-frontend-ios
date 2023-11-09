//
//  APIUtils.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/16/23.
//

import Foundation

//change these at your discretion
let ipAdress = "10.29.221.90" //Ip adress of computer running api
let local = false //whether you want to use a local api host or the cloud

let accessToken = "secrettoken"
let hostName = "https://scribe-backend-kb7z6w7ssq-ue.a.run.app"


//Extrac
func APIEvaluateToSVG(with svg: String, completion: @escaping (Result<String, Error>) -> Void) {
    // Define the URL for the FastAPI route
    var urlString = ""
    if local {
        urlString = "http://\(ipAdress):8000/evaluate/"
    }else{
        urlString = "\(hostName)/evaluate/"
    }
    
    if let url = URL(string: urlString) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the request headers and body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Create the request body data
        let requestBody = ["svg": StringToBase64(svg)]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        // Create a URLSession data task for the POST request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    do {
                        // Parse the response data (assuming it's JSON)
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let encodedImage = jsonResponse["answer_image"] as? String {
                            let answerImage = Base64ToString(encodedImage)
                            completion(.success(answerImage ?? ""))

                        } else {
                            completion(.failure(NSError(domain: "Response parsing error", code: 0, userInfo: nil)))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "Non-200 status code", code: response.statusCode, userInfo: nil)))
                }
            }
        }

        // Start the data task
        task.resume()
    }
}

func APIEvaluateToText(with svg: String, completion: @escaping (Result<String, Error>) -> Void) {
    // Define the URL for the FastAPI route
    var urlString = ""
    if local {
        urlString = "http://\(ipAdress):8000/evaluate/"
    }else{
        urlString = "\(hostName)/evaluate/"
    }
    
    if let url = URL(string: urlString) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the request headers and body

        print("acess token is", accessToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Create the request body data
        let requestBody = ["svg": StringToBase64(svg)]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        // Create a URLSession data task for the POST request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    do {
                        // Parse the response data (assuming it's JSON)
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let answer = jsonResponse["answer_text"] as? String {
                            completion(.success(answer))

                        } else {
                            completion(.failure(NSError(domain: "Response parsing error", code: 0, userInfo: nil)))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "Non-200 status code", code: response.statusCode, userInfo: nil)))
                }
            }
        }

        // Start the data task
        task.resume()
    }
}

func checkIfAuthorizedEmail(email: String, completion: @escaping (Bool?) -> Void) {
    var urlString = ""
    if local {
        urlString = "http://\(ipAdress):8000/check_email/\(email)"
    }else{
        urlString = "\(hostName)/check_email/\(email)"
    }
    
    let url = URL(string: urlString)

    let task = URLSession.shared.dataTask(with: url!) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        if httpResponse.statusCode == 200 {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Bool],
                   let result = json["result"] {
                    DispatchQueue.main.async {
                        completion(result)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }

    task.resume()
}

                               
func StringToBase64(_ inputString: String) -> String? {
   if let inputData = inputString.data(using: .utf8) {
       let base64String = inputData.base64EncodedString()
       return base64String
   }
   return nil
}

func Base64ToString(_ base64String: String) -> String? {
    if let data = Data(base64Encoded: base64String) {
        if let decodedString = String(data: data, encoding: .utf8) {
            return decodedString
        }
    }
    return nil
}


