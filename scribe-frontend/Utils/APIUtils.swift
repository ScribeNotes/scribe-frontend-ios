//
//  APIUtils.swift
//  scribe-frontend-ios
//
//  Created by Ty Todd on 10/16/23.
//

import Foundation

func sendPostRequest(with svg: String, completion: @escaping (Result<String, Error>) -> Void) {
    // Define the URL for the FastAPI route
    if let url = URL(string: "http://0.0.0.0:8000/evaluate/") {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the request headers and body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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


