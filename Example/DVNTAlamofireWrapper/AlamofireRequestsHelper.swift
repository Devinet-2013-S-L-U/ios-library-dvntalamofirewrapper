//
//  AlamofireRequestsHelper.swift
//
//
//  Created by Raúl Vidal Muiños on 18/6/18.
//  Copyright © 2018 Devinet 2013, S.L.U. All rights reserved.
//

import Alamofire
import SwiftyJSON
import DVNTAlamofireWrapper

protocol AlamofireRequestsHelperDelegate
{
    func connectionStatusDidChange(_ connectionType: ConnectionType)
}

class AlamofireRequestsHelper: DVNTAlamofireWrapperDelegate
{
    static let shared = AlamofireRequestsHelper()
    
    fileprivate let dispatchGroup = DispatchGroup()
    fileprivate let defaults = UserDefaults.standard
    fileprivate let alamofireInstance = DVNTAlamofireWrapper.shared
    
    fileprivate var host: String!
    fileprivate var retryTimes: UInt!
    fileprivate var countryCode: String!
    fileprivate var isRefreshingSession = false
    fileprivate var connectionType: ConnectionType!
    
    var delegate: AlamofireRequestsHelperDelegate?
    
    public init()
    {
        self.retryTimes = 3
        self.alamofireInstance.delegate = self
        self.alamofireInstance.setURLEncoding(encoding: .JSONEncodig)
    }
    
    public func closeAndInvalidateSession()
    {
        self.removeAllCookies()
        self.invalidateSession()
    }
    
    public func removeAllCookies()
    {
        self.alamofireInstance.cleanAllCookies()
    }
    
    public func invalidateSession()
    {
        self.alamofireInstance.invalidateSession()
    }
    
    public func startTrackingConnectionStatus()
    {
        self.alamofireInstance.startTrackingConnectionChanges()
    }
    
    public func stopTrackingConnectionStatus()
    {
        self.alamofireInstance.stopTrackingConnectionChanges()
    }
    
    // MARK: - Setters
    
    public func setRetryTimes(_ retryTimes: UInt)
    {
        self.retryTimes = retryTimes
    }
    
    // MARK: - Getters
    
    func getCookies() -> [HTTPCookie]?
    {
        return self.alamofireInstance.getCookies()
    }
    
    func getConnectionType() -> ConnectionType
    {
        return (self.connectionType == nil) ? ConnectionType.wifi : self.connectionType
    }
    
    // MARK: - AlamofireHelper delegate methods
    
    func connectionStatusDidChange(_ connectionType: ConnectionType)
    {
        self.connectionType = connectionType
        if let delegate = self.delegate {
            delegate.connectionStatusDidChange(connectionType)
        }
    }
    
    // MARK: - Requests
    
    func getRequest(success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
    {
        let url = Constants.API.GET
        self.alamofireInstance.performRequest(url, method: .get, parameters: nil, headers: nil, retryTimes: self.retryTimes, success: { (JSONResponse: JSON, statusCode: Int) in
            if statusCode == 200 {
                success(JSONResponse)
            }else{
                failure(nil)
            }
        }) { error in
            failure(error)
        }
    }
    
    func postRequest(success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
    {
        let url = Constants.API.POST
        self.alamofireInstance.performRequest(url, method: .post, parameters: nil, headers: nil, retryTimes: self.retryTimes, success: { (JSONResponse: JSON, statusCode: Int) in
            if statusCode == 200 {
                success(JSONResponse)
            }else{
                failure(nil)
            }
        }) { error in
            failure(error)
        }
    }
    
    func putRequest(success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
    {
        let url = Constants.API.PUT
        self.alamofireInstance.performRequest(url, method: .put, parameters: nil, headers: nil, retryTimes: self.retryTimes, success: { (JSONResponse: JSON, statusCode: Int) in
            if statusCode == 200 {
                success(JSONResponse)
            }else{
                failure(nil)
            }
        }) { error in
            failure(error)
        }
    }
    
    func deleteRequest(success: @escaping (JSON) -> Void, failure: @escaping (Error?) -> Void)
    {
        let url = Constants.API.DELETE
        self.alamofireInstance.performRequest(url, method: .delete, parameters: nil, headers: nil, retryTimes: self.retryTimes, success: { (JSONResponse: JSON, statusCode: Int) in
            if statusCode == 200 {
                success(JSONResponse)
            }else{
                failure(nil)
            }
        }) { error in
            failure(error)
        }
    }
}
