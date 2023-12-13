//
//  Network.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/4/21.
//

import Foundation

struct Networking {
    var urlSession = URLSession.shared

    func sendPostRequest(
        to url: URL,
        body: Data,
        then handler: @escaping (Result<Any, Error>) -> Void
    ) {
        // To ensure that our request is always sent, we tell
        // the system to ignore all local cache data:
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        request.httpMethod = "POST"
        request.httpBody = body
    
        CLog.shared.metric?.start(request: request)

        let task = urlSession.dataTask(
            with: request,
            completionHandler: { data, response, error in
                
                CLog.shared.metric?.cancel(request: request, response: response)
                
                if let urlResponse = response as? HTTPURLResponse,
                   urlResponse.statusCode == 500 {
                    handler(.failure(NSError(domain: "", code: 500, userInfo: [:]) as Error))
                    return
                }
                if let error = error {
                    handler(.failure(error))
                    return
                }
                if let data = data {
                    do {
                        let object = try JSONSerialization.jsonObject(with: data, options: [])
                        handler(.success(object))
                    } catch {
                        CLog.print(.error, .api, error)
                        handler(.failure(error))
                    }
                }
            }
        )

        task.resume()
    }
}
