//
//  CustomSession.swift
//  DVNTAlamofireWrapper
//
//  Created by Raúl Vidal Muiños on 20/11/20.
//

import UIKit
import Alamofire
import Foundation

class CustomSession: Session {
    
    
    public convenience init(configuration: URLSessionConfiguration = URLSessionConfiguration.af.default, delegate: SessionDelegate = SessionDelegate(), rootQueue: DispatchQueue = DispatchQueue(label: "org.dvntalamofiremanager.session.rootQueue"), startRequestsImmediately: Bool = true, requestQueue: DispatchQueue? = DispatchQueue(label: "com.dvntalamofiremanager.session.requestQueue"), serializationQueue: DispatchQueue? = DispatchQueue(label: "com.dvntalamofiremanager.session.serializationQueue"), interceptor: RequestInterceptor? = nil, serverTrustManager: ServerTrustManager? = nil, redirectHandler: RedirectHandler? = nil, cachedResponseHandler: CachedResponseHandler? = nil, eventMonitors: [EventMonitor] = []) {
        
        precondition(configuration.identifier == nil, "Alamofire does not support background URLSessionConfigurations.")

        let delegateQueue = OperationQueue()
        delegateQueue.underlyingQueue = rootQueue
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.name = "org.alamofire.session.sessionDelegateQueue"
        
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

        self.init(session: session,
                  delegate: delegate,
                  rootQueue: rootQueue,
                  startRequestsImmediately: startRequestsImmediately,
                  requestQueue: requestQueue,
                  serializationQueue: serializationQueue,
                  interceptor: interceptor,
                  serverTrustManager: serverTrustManager,
                  redirectHandler: redirectHandler,
                  cachedResponseHandler: cachedResponseHandler,
                  eventMonitors: eventMonitors)
        
    }
}
