//
//  ViewController.swift
//  ARKit-SCN-Download
//
//  Created by Aruna Udayanga on 10/1/19.
//  Copyright © 2019 Aruna Udayanga. All rights reserved.
//

import UIKit
import ARKit
import Alamofire
import ZIPFoundation

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    private var objectNode: SCNNode?
    let modelsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.loadNodeWithName("art", completion: { (SCNNode) -> Void in
            SCNNode!.scale = SCNVector3(0.001, 0.001, 0.001)
            SCNNode!.position = SCNVector3(0.9, 0, 0.8)
            self.sceneView.scene.rootNode.addChildNode(SCNNode!)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        sceneView.session.run(configuration)
    }

    func loadNodeWithName(_ modelName: String, completion: @escaping (SCNNode?) -> Void) {
        // Check that assets for that model are not already downloaded
        let fileManager = FileManager.default
        let dirForModel = modelsDirectory.appendingPathComponent(modelName)
        let dirExists = fileManager.fileExists(atPath: dirForModel.path)
        if dirExists {
            completion(loadNodeWithIdFromDisk(modelName))
        } else {
            let dumbURL = "https://....<zip file url>"
            downloadZip(from: dumbURL, at: modelName) {
                if let url = $0 {
                    print("Downloaded and unzipped at: \(url.absoluteString)")
                    completion(self.loadNodeWithIdFromDisk(modelName))
                } else {
                    print("Something went wrong!")
                    completion(nil)
                }
            }
        }
    }
    
    func loadNodeWithIdFromDisk(_ modelName: String) -> SCNNode? {
        let fileManager = FileManager.default
        let dirForModel = modelsDirectory.appendingPathComponent(modelName)
        do {
            let files = try fileManager.contentsOfDirectory(atPath: dirForModel.path)
            if let objFile = files.first(where: { $0.hasSuffix(".scnassets") }) {
                let objScene = try? SCNScene(url: dirForModel.appendingPathComponent("art.scnassets/SCN object Name.scn"), options: nil)
                // let objNode = objScene?.rootNode.firstChild()
                let objNode = objScene?.rootNode.childNode(withName: "SCN object child name", recursively: true)
                return objNode
            } else {
                print("No obj file in directory: \(dirForModel.path)")
                return nil
            }
        } catch {
            print("Could not enumarate files or load scene: \(error)")
            return nil
        }
    }
    
    // download scn Zip file
    func downloadZip(from urlString: String, at destFileName: String, completion: ((URL?) -> Void)?) {
        print("Downloading \(urlString)")
        let fullDestName = destFileName + ".zip"
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileURL = self.modelsDirectory.appendingPathComponent(fullDestName)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(urlString, to: destination).response { response in
            let error = response.error
            if error == nil {
                if let filePath = response.destinationURL?.path {
                    let nStr = NSString(string: filePath)
                    let id = NSString(string: nStr.lastPathComponent).deletingPathExtension
                    print(response)
                    print("file downloaded at: \(filePath)")
                    let fileManager = FileManager()
                    let sourceURL = URL(fileURLWithPath: filePath)
                    var destinationURL = self.modelsDirectory
                    destinationURL.appendPathComponent(id)
                    do {
                        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                        try fileManager.unzipItem(at: sourceURL, to: destinationURL)
                        completion?(destinationURL)
                    } catch {
                        completion?(nil)
                        print("Extraction of ZIP archive failed with error: \(error)")
                    }
                } else {
                    completion?(nil)
                    print("File path not found")
                }
            } else {
                // Handle error
                completion?(nil)
            }
        }
    }
}

