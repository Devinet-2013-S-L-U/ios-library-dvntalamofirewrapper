//
//  DVNTAlamofireWrapper.swift
//
//
//  Created by Raúl Vidal Muiños on 9/4/19.
//  Copyright © 2019 Raúl Vidal Muiños. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Reachability

public enum ConnectionType
{
    case none
    case wifi
    case celular
}

public enum EncodingType
{
    case urlEncoding
    case JSONEncodig
}

public protocol DVNTAlamofireWrapperDelegate
{
    func connectionStatusDidChange(_ connectionType: ConnectionType)
}

public class DVNTAlamofireWrapper
{
    public static let shared = DVNTAlamofireWrapper()

    private final let reachability = try! Reachability()
    
    private final var sessionManager: Session!
    private final var connectionType: ConnectionType!
    private final var networkActivityIndicatorCounter = 0
    private final var encoding: EncodingType = .urlEncoding
    
    public var delegate: DVNTAlamofireWrapperDelegate?
    
    init()
    {        
        let configuration = URLSessionConfiguration.default
        
        configuration.httpCookieStorage = .shared
        configuration.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        
        self.sessionManager = CustomSession(configuration: configuration, delegate: SessionDelegate(fileManager: .default), rootQueue: DispatchQueue(label: "es.devinet.dvntAlamofireWrapper.session.rootQueue"), startRequestsImmediately: true)
    }
    
    public final func setURLEncoding(encoding: EncodingType)
    {
        self.encoding = encoding
    }
    
    public final func startTrackingConnectionChanges()
    {
        print("⚠️ DVNTAlamofireWrapper: Starting connection track service...")
        do{
            try self.reachability.startNotifier()
            self.initializeNotificationHandlers()
            self.checkConnectionType(self.reachability)
            print("✅ DVNTAlamofireWrapper: Connection track service up and running!")
        }catch{
            print("👎 DVNTAlamofireWrapper: Reachability notifier could not be started.")
        }
    }
    
    public final func stopTrackingConnectionChanges()
    {
        self.reachability.stopNotifier()
        self.resignNotificationHandlers()
        print("🛑 DVNTAlamofireWrapper: Connection track service stopped.")
    }
    
    public final func chekIfURLIsReachable(_ hostName: String, completion: @escaping (Bool) -> Void)
    {
        if let url = URL(string: hostName) {
            let checkSession = Foundation.URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 1.0

            let task = checkSession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
                    completion(httpResp.statusCode == 200)
                }else{
                    completion(false)
                }
            })

            task.resume()
        }else{
            completion(false)
        }
    }
    
    // MARK: - Setters
    
    public final func cleanAllCookies()
    {
        URLCache.shared.removeAllCachedResponses()
        if self.sessionManager.session.configuration.httpCookieStorage != nil {
            self.sessionManager.session.configuration.httpCookieStorage!.removeCookies(since: Date(timeIntervalSince1970: 0))
        }
    }
    
    public final func getCookies() -> [HTTPCookie]?
    {
        return self.sessionManager.session.configuration.httpCookieStorage?.cookies
    }
    
    public final func invalidateSession()
    {
        self.resignNotificationHandlers()
        self.sessionManager.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { $0.cancel() }
            uploadData.forEach { $0.cancel() }
            downloadData.forEach { $0.cancel() }
        }
        self.sessionManager.session.invalidateAndCancel()
    }
    
    public final func performRequest(_ url: String, identity: String? = nil, password: String? = nil, method: HTTPMethod, parameters: Parameters?, headers: HTTPHeaders?, interceptors: [RequestInterceptor] = [], retryTimes: UInt, shouldCheckJSONResponseIntegrity: Bool = true, success: @escaping (JSON, Int) -> Void, failure: @escaping (Error?) -> Void) {
        print("⚠️ DVNTAlamofireWrapper: Starting request to \(url)...")

        let retryInterceptor = RetryPolicy(retryLimit: retryTimes, exponentialBackoffBase: 2)
        var allInterceptors = interceptors
        allInterceptors.append(retryInterceptor)

        let combinedInterceptor = CompositeInterceptor(interceptors: allInterceptors)

        let request = self.sessionManager.request(url, method: method, parameters: parameters, encoding: self.getEncoding(), headers: headers, interceptor: combinedInterceptor)

        if let identity = identity, let password = password {
            request.authenticate(username: identity, password: password)
        }

        if shouldCheckJSONResponseIntegrity {
            request.responseDecodable(of: JSON.self) { response in
                switch response.result {
                case .success:
                    print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                    if let responseValue = response.value {
                        success(JSON(responseValue), response.response?.statusCode ?? -1)
                    } else {
                        success(JSON(), response.response?.statusCode ?? -1)
                    }
                case let .failure(error):
                    print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                    failure(error)
                }
            }
        } else {
            request.response(completionHandler: { response in
                switch response.result {
                case .success:
                    print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                    if let responseValue = response.value, let safeResponse = responseValue {
                        success(JSON(safeResponse), response.response?.statusCode ?? -1)
                    } else {
                        success(JSON(), response.response?.statusCode ?? -1)
                    }
                case let .failure(error):
                    print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                    failure(error)
                }
            })
        }
    }
    
    public final func performRequest(_ url: String, identity: String? = nil, password: String? = nil, method: HTTPMethod, parameters: Parameters?, headers: HTTPHeaders?, interceptors: [RequestInterceptor] = [], retryTimes: UInt, success: @escaping (Data, Int) -> Void, failure: @escaping (Error?) -> Void)
    {
        print("⚠️ DVNTAlamofireWrapper: Starting request to \(url)...")
        
        let retryInterceptor = RetryPolicy(retryLimit: retryTimes, exponentialBackoffBase: 2)
        var allInterceptors = interceptors
        allInterceptors.append(retryInterceptor)

        let combinedInterceptor = CompositeInterceptor(interceptors: allInterceptors)
        
        let request = self.sessionManager.request(url, method: method, parameters: parameters, encoding: self.getEncoding(), headers: headers, interceptor: combinedInterceptor)
        
        if let identity = identity, let password = password {
            request.authenticate(username: identity, password: password)
        }
        
        request.responseData { response in
            switch response.result {
            case .success:
                print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                if let responseValue = response.value {
                    success(Data(responseValue), response.response?.statusCode ?? -1)
                }else{
                    success(Data(), response.response?.statusCode ?? -1)
                }
            case let .failure(error):
                print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                failure(error)
            }
        }
    }
    
    public final func uploadData(_ url: String, data: Data, identity: String? = nil, password: String? = nil, method: HTTPMethod, headers: HTTPHeaders?, interceptors: [RequestInterceptor] = [], retryTimes: UInt, success: @escaping (JSON, Int) -> Void, uploadProgress: @escaping (Double) -> Void, failure: @escaping (Error?) -> Void)
    {
        print("⚠️ DVNTAlamofireWrapper: Starting request to \(url)...")
        
        let retryInterceptor = RetryPolicy(retryLimit: retryTimes, exponentialBackoffBase: 2)
        var allInterceptors = interceptors
        allInterceptors.append(retryInterceptor)

        let combinedInterceptor = CompositeInterceptor(interceptors: allInterceptors)
        
        let request = self.sessionManager.upload(data, to: url, method: method, headers: headers, interceptor: combinedInterceptor, fileManager: .default)
        
        if let identity = identity, let password = password {
            request.authenticate(username: identity, password: password)
        }
        
        request.responseDecodable(of: JSON.self) { response in
            switch response.result {
            case .success:
                print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                if let responseValue = response.value {
                    success(JSON(responseValue), response.response?.statusCode ?? -1)
                }else{
                    success(JSON(), response.response?.statusCode ?? -1)
                }
            case let .failure(error):
                print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                failure(error)
            }
        }.uploadProgress { progress in
            print("🆙 AlamofireRequestHelper: Uploading data: \(Int(progress.fractionCompleted*100))%")
            uploadProgress(progress.fractionCompleted)
        }
    }
    
    public final func uploadData(_ url: String, data: Data, identity: String? = nil, password: String? = nil, method: HTTPMethod, headers: HTTPHeaders?, interceptors: [RequestInterceptor] = [], retryTimes: UInt, success: @escaping (Data, Int) -> Void, uploadProgress: @escaping (Double) -> Void, failure: @escaping (Error?) -> Void)
    {
        print("⚠️ DVNTAlamofireWrapper: Starting request to \(url)...")
        
        let retryInterceptor = RetryPolicy(retryLimit: retryTimes, exponentialBackoffBase: 2)
        var allInterceptors = interceptors
        allInterceptors.append(retryInterceptor)

        let combinedInterceptor = CompositeInterceptor(interceptors: allInterceptors)
        
        let request = self.sessionManager.upload(data, to: url, method: method, headers: headers, interceptor: combinedInterceptor, fileManager: .default)
        
        if let identity = identity, let password = password {
            request.authenticate(username: identity, password: password)
        }
        
        request.responseData { response in
            switch response.result {
            case .success:
                print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                if let responseValue = response.value {
                    success(Data(responseValue), response.response?.statusCode ?? -1)
                }else{
                    success(Data(), response.response?.statusCode ?? -1)
                }
            case let .failure(error):
                print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                failure(error)
            }
        }.uploadProgress { progress in
            print("🆙 AlamofireRequestHelper: Uploading data: \(Int(progress.fractionCompleted*100))%")
            uploadProgress(progress.fractionCompleted)
        }
    }
    
    public final func uploadMultipartData(_ url: String, data: Data, name: String, fileName: String, mimeType: String, identity: String? = nil, password: String? = nil, method: HTTPMethod, headers: HTTPHeaders?, interceptors: [RequestInterceptor] = [], retryTimes: UInt, success: @escaping (Data, Int) -> Void, uploadProgress: @escaping (Double) -> Void, failure: @escaping (Error?) -> Void)
    {
        print("⚠️ DVNTAlamofireWrapper: Starting request to \(url)...")
        
        let retryInterceptor = RetryPolicy(retryLimit: retryTimes, exponentialBackoffBase: 2)
        var allInterceptors = interceptors
        allInterceptors.append(retryInterceptor)

        let combinedInterceptor = CompositeInterceptor(interceptors: allInterceptors)
        
        let request = self.sessionManager.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(data, withName: name, fileName: fileName, mimeType: mimeType)
            }, to: url, usingThreshold: UInt64.init(), method: method, headers: headers, interceptor: combinedInterceptor, fileManager: .default)
                
        if let identity = identity, let password = password {
            request.authenticate(username: identity, password: password)
        }
        
        request.responseData { response in
            switch response.result {
            case .success:
                print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                if let responseValue = response.value {
                    success(Data(responseValue), response.response?.statusCode ?? -1)
                }else{
                    success(Data(), response.response?.statusCode ?? -1)
                }
            case let .failure(error):
                print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                failure(error)
            }
        }.uploadProgress { progress in
            print("🆙 AlamofireRequestHelper: Uploading data: \(Int(progress.fractionCompleted*100))%")
            uploadProgress(progress.fractionCompleted)
        }
    }
    
    public final func uploadMultipartData(_ url: String, data: Data, name: String, fileName: String, mimeType: String, identity: String? = nil, password: String? = nil, method: HTTPMethod, headers: HTTPHeaders?, interceptors: [RequestInterceptor] = [], retryTimes: UInt, success: @escaping (JSON, Int) -> Void, uploadProgress: @escaping (Double) -> Void, failure: @escaping (Error?) -> Void)
    {
        print("⚠️ DVNTAlamofireWrapper: Starting request to \(url)...")
        
        let retryInterceptor = RetryPolicy(retryLimit: retryTimes, exponentialBackoffBase: 2)
        var allInterceptors = interceptors
        allInterceptors.append(retryInterceptor)

        let combinedInterceptor = CompositeInterceptor(interceptors: allInterceptors)
        
        let request = self.sessionManager.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(data, withName: name, fileName: fileName, mimeType: mimeType)
            }, to: url, usingThreshold: UInt64.init(), method: method, headers: headers, interceptor: combinedInterceptor, fileManager: .default)
                
        if let identity = identity, let password = password {
            request.authenticate(username: identity, password: password)
        }
        
        request.responseDecodable(of: JSON.self) { response in
            switch response.result {
            case .success:
                print("✅ DVNTAlamofireWrapper: Request to \(url) completed with \(response.response?.statusCode ?? -1) in \(response.metrics?.taskInterval.duration ?? -1)s")
                if let responseValue = response.value {
                    success(JSON(responseValue), response.response?.statusCode ?? -1)
                }else{
                    success(JSON(), response.response?.statusCode ?? -1)
                }
            case let .failure(error):
                print("⛔️ DVNTAlamofireWrapper: Request to \(url) thrown an error: \(error.localizedDescription)")
                failure(error)
            }
        }.uploadProgress { progress in
            print("🆙 AlamofireRequestHelper: Uploading data: \(Int(progress.fractionCompleted*100))%")
            uploadProgress(progress.fractionCompleted)
        }
    }
    
    // MARK: - Notification Handler
    
    @objc private final func reachabilityChanged(notification: NSNotification)
    {
        guard let reachability = notification.object as? Reachability else { return }
        self.checkConnectionType(reachability)
    }
    
    private final func checkConnectionType(_ reachability: Reachability)
    {
        switch reachability.connection {
        case .wifi: self.connectionType = ConnectionType.wifi
        case .cellular: self.connectionType = ConnectionType.celular
        default: self.connectionType = ConnectionType.none
        }
        
        if let delegate = self.delegate {
            delegate.connectionStatusDidChange(self.connectionType)
        }
    }
    
    // MARK: - Other methods
    
    private final func initializeNotificationHandlers()
    {
        self.resignNotificationHandlers()
        NotificationCenter.default.addObserver(self, selector:#selector(self.reachabilityChanged), name: .reachabilityChanged, object: nil)
    }
    
    private final func resignNotificationHandlers()
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    private final func getEncoding() -> ParameterEncoding
    {
        switch self.encoding {
        case .JSONEncodig: return JSONEncoding.default
        case .urlEncoding: return URLEncoding.default
        }
    }
}
