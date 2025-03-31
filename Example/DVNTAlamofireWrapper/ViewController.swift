//
//  ViewController.swift
//  DVNTAlamofireWrapper
//
//  Created by Raúl Vidal Muiños on 04/09/2019.
//  Copyright (c) 2019 Raúl Vidal Muiños. All rights reserved.
//

import UIKit
import DVNTAlamofireWrapper

class ViewController: UIViewController
{
    private final let alamofireManager = AlamofireRequestsHelper.shared
    
    private final var isTrackingConnection = false
    
    @IBOutlet weak var connectionStatus: UILabel!
    @IBOutlet weak var realTimeConnectionTrackingButton: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.alamofireManager.delegate = self
    }
    
    // MARK: - IBActions
    
    @IBAction func getRequestButtonAction(_ sender: Any)
    {
        self.alamofireManager.getRequest(success: { (JSONResponse) -> Void in
            print("😀 [GET] JSON DATA RECEIVED: \(JSONResponse)")
        }, failure: {(error) -> Void in
            if let error = error {
                print("😟 [GET] REQUEST ERROR: \(error.localizedDescription)")
            }else{
                print("😟 [GET] REQUEST UNKNOWN ERROR")
            }
        })
    }
    
    @IBAction func postRequestButtonAction(_ sender: Any)
    {
        self.alamofireManager.postRequest(success: { (JSONResponse) -> Void in
            print("😀 [POST] JSON DATA RECEIVED: \(JSONResponse)")
        }, failure: {(error) -> Void in
            if let error = error {
                print("😟 [POST] REQUEST ERROR: \(error.localizedDescription)")
            }else{
                print("😟 [POST] REQUEST UNKNOWN ERROR")
            }
        })
    }
    
    @IBAction func putRequestButtonAction(_ sender: Any)
    {
        self.alamofireManager.putRequest(success: { (JSONResponse) -> Void in
            print("😀 [PUT] JSON DATA RECEIVED: \(JSONResponse)")
        }, failure: {(error) -> Void in
            if let error = error {
                print("😟 [PUT] REQUEST ERROR: \(error.localizedDescription)")
            }else{
                print("😟 [PUT] REQUEST UNKNOWN ERROR")
            }
        })
    }
    
    @IBAction func deleteRequestButtonAction(_ sender: Any)
    {
        self.alamofireManager.deleteRequest(success: { (JSONResponse) -> Void in
            print("😀 [DELETE] JSON DATA RECEIVED: \(JSONResponse)")
        }, failure: {(error) -> Void in
            if let error = error {
                print("😟 [DELETE] REQUEST ERROR: \(error.localizedDescription)")
            }else{
                print("😟 [DELETE] REQUEST UNKNOWN ERROR")
            }
        })
    }
    
    @IBAction func startOrStopConnectionTrackingButtonAction(_ sender: Any)
    {
        if self.isTrackingConnection {
            self.alamofireManager.stopTrackingConnectionStatus()
            self.connectionStatus.text = "Tracking is disabled"
        }else{
            self.alamofireManager.startTrackingConnectionStatus()
        }
        
        self.isTrackingConnection = !self.isTrackingConnection
        self.realTimeConnectionTrackingButton.setTitle(self.isTrackingConnection ? "Stop connection tracking" : "Start connection tracking", for: .normal)
    }
}

extension ViewController: AlamofireRequestsHelperDelegate
{
    func connectionStatusDidChange(_ connectionType: ConnectionType) {
        switch connectionType {
        case .celular:
            self.connectionStatus.text = "Celular"
        case .wifi:
            self.connectionStatus.text = "Wi-Fi"
        case .none:
            self.connectionStatus.text = "No internet connection"
        }
    }
}
