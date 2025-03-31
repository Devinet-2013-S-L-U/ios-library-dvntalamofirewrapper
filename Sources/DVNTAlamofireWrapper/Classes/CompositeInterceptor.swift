//
//  CompositeInterceptor.swift
//  DVNTAlamofireWrapper
//
//  Created by Raúl Vidal Muiños on 5/9/24.
//

import Alamofire
import Foundation

struct CompositeInterceptor: RequestInterceptor {
    private var interceptors: [RequestInterceptor]
    
    init(interceptors: [RequestInterceptor]) {
        self.interceptors = interceptors
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let group = DispatchGroup()
        var currentRequest = urlRequest
        var firstError: Error?

        for interceptor in interceptors {
            group.enter()
            interceptor.adapt(currentRequest, for: session) { result in
                switch result {
                case .success(let adaptedRequest):
                    currentRequest = adaptedRequest
                case .failure(let error):
                    firstError = firstError ?? error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(currentRequest))
            }
        }
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        let group = DispatchGroup()
        var retryResult: RetryResult = .doNotRetry
        var retryResults = [RetryResult]()

        for interceptor in interceptors {
            group.enter()
            interceptor.retry(request, for: session, dueTo: error) { result in
                retryResults.append(result)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            for result in retryResults {
                switch result {
                case .retry, .retryWithDelay(_):
                    retryResult = result
                    break
                default:
                    continue
                }
            }
            completion(retryResult)
        }
    }
}
