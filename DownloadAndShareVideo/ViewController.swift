//
//  ViewController.swift
//  DownloadAndShareVideo
//
//  Created by Sukumar Anup Sukumaran on 21/10/18.
//  Copyright © 2018 TechTonic. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var btnShareVideo: UIButton!
    
     let videoPlayer = AVPlayerViewController()
     let playerLayer = AVPlayerLayer()
    
    var progress: Float = 0.0
    var task: URLSessionTask!
    var percentageWritten: Float = 0.0
    var taskTotalBytesWritten = 0
    var taskTotalBytesExpectedWritten = 0
    
    lazy var session: URLSession = {
       let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        return session
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNotificWhenVideoEnds()
    }
    
    //MARK: SET Notification When VIDEO ENDS
    func setNotificWhenVideoEnds() {
        NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying(note:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification){
        print("dataEnded")
        //dismiss(animated: true, completion: nil)
         self.playerLayer.removeFromSuperlayer()
    }
    
    
    @IBAction func shareVideoAction(_ sender: Any) {
        
          var hud =  MBProgressHUD.showAdded(to: self.view, animated: true)
          progress = 0.0
         hud?.mode = MBProgressHUDMode.determinateHorizontalBar
         hud?.isUserInteractionEnabled = true
         hud?.labelText = NSLocalizedString("Downloading....", comment: "HUD Downloading title")
        DispatchQueue.global(qos: .default).async {
            // Do something useful in the background and update the HUD periodically.
            self.doSomeWorkWithProgress()
            DispatchQueue.main.async {
                hud?.labelText = NSLocalizedString("Just wait....", comment: "HUD Downloading title")
            }
        }
        
        //http://159.65.154.78:8002/storage/whatsapp-status/video/2018/07/26/Zd1XMyCZIpd3XHREyWFOou9ig98IzcJKxEYR8fzd.mp4
        //http://www.exit109.com/~dnn/clips/RW20seconds_1.mp4
        let videoPath = "http://www.exit109.com/~dnn/clips/RW20seconds_1.mp4"
        
        let s = videoPath
        let url = NSURL(string:s)!
        let req = NSMutableURLRequest(url:url as URL)
        let task = self.session.downloadTask(with: req as URLRequest)
        self.task = task
        task.resume()
        
    }
    
    //MARK:- share video
    func doSomeWorkWithProgress() {
        while progress < 1.0 {
            DispatchQueue.main.async {
                print(self.progress)
                MBProgressHUD(for: self.view)?.progress = self.progress
            }
            usleep(50000)
        }
    }
    //MARK: VIDEO LAYER
    func callPayerAsALayer(url: URL) {
       // let videoURL = URL(string: "https://www.electronicvillage.org/evquizapp/upload/questions/12.mp4")
        let player = AVPlayer(url: url)
        
        //let playerLayer = AVPlayerLayer(player: player)
        playerLayer.player = player
        playerLayer.frame = self.view.bounds
        
        self.view.layer.addSublayer(playerLayer)
        
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        self.view.layer.insertSublayer(playerLayer, at: 0)
//        player.seek(to: CMTime.zero)
        player.play()
    }
    
    //MARK: As Separate Player
    func asSeperatePlayer(url: URL) {
        //"http://jplayer.org/video/m4v/Big_Buck_Bunny_Trailer.m4v"
        let video = AVPlayer(url: url)
        //
        videoPlayer.player = video
        videoPlayer.showsPlaybackControls = false
        videoPlayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        present(videoPlayer, animated: true) {
            print("Playing...")
       
            video.play()
            video.accessibilityElementsHidden = true
            
        }
    }
    


}


extension ViewController: URLSessionDownloadDelegate {
    
    //MARK:- URL Session delegat
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        print("downloaded \(100*totalBytesWritten/totalBytesExpectedToWrite)")
        taskTotalBytesWritten = Int(totalBytesWritten)
        taskTotalBytesExpectedWritten = Int(totalBytesExpectedToWrite)
        percentageWritten = Float(taskTotalBytesWritten) / Float(taskTotalBytesExpectedWritten)
        print(percentageWritten)
        //  let x = Double(percentageWritten).rounded(toPlaces: 2)
        let x = String(format:"%.2f", percentageWritten)
        print(x)
        self.progress = Float(x)!
        print(progress)
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(" Error = \(String(describing: error?.localizedDescription))😩")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finished downloading!😄")
        
        let fileManager = FileManager()
        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("directoryURL = \(directoryURL)😄")
        
        let docDirectoryURL = NSURL(fileURLWithPath: "\(directoryURL)")
        print("docDirectoryURL = \(docDirectoryURL)😄")
        
        // Get the original file name from the original request.
        guard let originalURL = downloadTask.originalRequest?.url else {print("originalURL😩");return}
        print("originalURL = \(originalURL)")
       //
       
        
        let destinationFilename = downloadTask.originalRequest?.url?.lastPathComponent
        print("destinationFilename = \(destinationFilename!)😄")
        
        let destinationURL =  docDirectoryURL.appendingPathComponent("\(destinationFilename!)")
        print("destinationURL = \(String(describing: destinationURL))😄")
        
        if let path = destinationURL?.path {
            if fileManager.fileExists(atPath: path){
                do{
                    try fileManager.removeItem(at: destinationURL!)
                } catch let error{
                    print(" Erorr = \(error.localizedDescription)😩")
                }
            }
        }
        
        do
        {
            try fileManager.copyItem(at: location, to: destinationURL!)
        }
        catch {
            print("Error while copy file")
            
        }
        
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
         callPayerAsALayer(url: destinationURL!)
        // asSeperatePlayer(url: destinationURL!)
       // activityAlertView(destinationURL: destinationURL!)
        
    }
    
    //MARK: ActivityAlertView
    func activityAlertView(destinationURL: URL) {
        let objectsToShare = [destinationURL]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare , applicationActivities: nil)
        activityVC.setValue("Video", forKey: "subject")
        if #available(iOS 9.0, *) {
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.mail, UIActivity.ActivityType.message, UIActivity.ActivityType.openInIBooks, UIActivity.ActivityType.postToTencentWeibo, UIActivity.ActivityType.postToVimeo, UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.print]
        } else {
            // Fallback on earlier versions
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.mail, UIActivity.ActivityType.message, UIActivity.ActivityType.postToTencentWeibo, UIActivity.ActivityType.postToVimeo, UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.print ]
        }
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.btnShareVideo
            popoverController.sourceRect = self.btnShareVideo.bounds
        }
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    
}
