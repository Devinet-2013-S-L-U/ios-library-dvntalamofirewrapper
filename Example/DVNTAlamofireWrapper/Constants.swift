//
//  Constants.swift
//  
//
//  Created by Raúl Vidal Muiños on 9/4/19.
//  Copyright © 2020 Devinet 2013, S.L.U. All rights reserved.
//

import UIKit

class Constants: NSObject
{
    // MARK: - APi
    
    struct API
    {
        private static let BASE_URL = "http://httpbin.org"
        static let GET = BASE_URL + "/get"
        static let POST = BASE_URL + "/post"
        static let PUT = BASE_URL + "/put"
        static let DELETE = BASE_URL + "/delete"
    }
}
