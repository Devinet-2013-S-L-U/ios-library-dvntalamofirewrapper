//
//  AppDelegate.swift
//  DVNTAlamofireWrapper
//
//  Created by Raúl Vidal Muiños on 04/09/2019.
//  Copyright (c) 2019 Raúl Vidal Muiños. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        AlamofireRequestsHelper.shared.closeAndInvalidateSession()
        AlamofireRequestsHelper.shared.stopTrackingConnectionStatus()
    }
}

