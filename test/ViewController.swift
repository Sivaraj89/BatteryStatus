//
//  ViewController.swift
//  test
//
//  Created by Wipro on 28/06/18.
//  Copyright © 2018 Wipro. All rights reserved.
//

import UIKit
import FirebaseStorage


class ViewController: UIViewController, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate{


    override func viewDidLoad() {
        super.viewDidLoad()
        
       UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        let loop = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.batteryStatus), userInfo: nil, repeats: true)
        RunLoop.current.add(loop, forMode: .commonModes)
    }

    override func viewDidAppear(_ animated: Bool) {
        let Alert = UIAlertController(title: "Alert", message: "plz open target application", preferredStyle: UIAlertControllerStyle.alert)
        self.present(Alert, animated: true, completion: nil)
    }

  @objc func batteryStatus(){
        let myDevice = UIDevice.current
        myDevice.isBatteryMonitoringEnabled = true
        let batLeft: Float = myDevice.batteryLevel
        let i: UIDeviceBatteryState = myDevice.batteryState
        let batinfo = Int((batLeft * 100)) as NSNumber
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date) 
        print(batinfo,dateString)
        
                if let filepath = Bundle.main.path(forResource: "data", ofType: "json") {
                    do {
                        let contents = try String(contentsOfFile: filepath)
                        let data = contents.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                        do {
                            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
                            var andict:Dictionary = json
                            var dict1 = andict["per_ip_data"] as! Dictionary<String, AnyObject>
                            var dict2 = dict1["section_data"] as! Array<AnyObject>
                            var batteryObj = dict2[0] as! [String:AnyObject]
                            batteryObj["battery"] = batinfo
                            dict2[0] = batteryObj as AnyObject
                            dict1["section_data"] = dict2 as AnyObject
                            andict["per_ip_data"] = dict1 as AnyObject
                            dict1 = andict
                            print(andict)
                            let jsonData = try? JSONSerialization.data(withJSONObject: andict, options: [])
                            let jsonString = String(data: jsonData!, encoding: .utf8)
                            let datas: Data = NSKeyedArchiver.archivedData(withRootObject: andict)
                            var ref: DatabaseReference!
                            ref = Database.database().reference()
                            
                            let request = NSMutableURLRequest(url:NSURL(string: "http://54.164.87.105:8080/networkmonitoring-6-Apr-17/appdata")! as URL)
                            request.httpMethod = "POST"
                            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
                            uploadFiles(request: request, data: jsonData as! NSData)
                        } catch let error as NSError {
                            print("Failed to load: \(error.localizedDescription)")
                        }

                    } catch {
                        print("Fetched")
                    }
                } else {
                    print("not found")
                }
        
        
        
    }
    func uploadFiles(request: NSURLRequest, data: NSData) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        print(request)
        let task = session.uploadTask(with: request as URLRequest, from: data as Data)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            print("session \(session) occurred error \(String(describing: error?.localizedDescription))")
        } else {
            print(error?.localizedDescription as Any)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        print("session \(session) uploaded \(uploadProgress * 100)%.")
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("session \(session), received response \(response)")
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print(data)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

