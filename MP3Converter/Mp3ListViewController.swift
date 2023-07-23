//
//  Mp3ListViewController.swift
//  MP3Converter
//
//  Created by Atik  on 6/6/23.
//

import UIKit
import AVFoundation
import AVKit

class Mp3ListViewController: UITableViewController {
    
//    var fileURLs: [URL] = []
    var fileURLs: [FileURL] = []
    var audioPlayer: AVAudioPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "CustomCell", bundle: nil), forCellReuseIdentifier: "ReusableCustomCell")
        
        retrieveSavedFileURLs()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
        
    }
    
    func retrieveSavedFileURLs() {
        let fileManager = FileManager.default
        let documentsURL = getDocumentsDirectory()

        do {
            // Retrieve the contents of the document directory
            let contents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            let fileExtensions: Set<String> = ["mp3"]
            fileURLs = contents.filter { fileExtensions.contains($0.pathExtension) }
                .map { FileURL(url: $0) }
//            fileURLs = contents.filter { fileExtensions.contains($0.pathExtension) }
            
        } catch {
            print("Error retrieving file URLs: \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fileURLs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReusableCustomCell", for: indexPath) as! CustomCell
        
        let fileURL = fileURLs[indexPath.row]
        cell.mp3Title.text = fileURL.url.lastPathComponent
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let fileURL = fileURLs[indexPath.row]
        
        presentMediaPlayer(with: fileURL.url)
    }
    
    func presentMediaPlayer(with url: URL) {
        let player = AVPlayer(url: url)

        playerViewController = AVPlayerViewController()
        playerViewController?.player = player

        present(playerViewController!, animated: true) {
            player.play()
        }
    }
    
    //    Long Press Handle
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                showActionSheet(for: indexPath)
            }
        }
    }
    
    func showActionSheet(for indexPath: IndexPath) {
        
        let fileURL = fileURLs[indexPath.row]
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let playAction = UIAlertAction(title: "Play", style: .default) { _ in
            self.playAudio(at: fileURL.url)
        }
        actionSheet.addAction(playAction)
        
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            self.shareFile(at: fileURL.url)
        }
        actionSheet.addAction(shareAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteFile(at: fileURL.url, indexPath: indexPath)
        }
        actionSheet.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
        
    func playAudio(at url: URL) {
        let player = AVPlayer(url: url)

        playerViewController = AVPlayerViewController()
        playerViewController?.player = player

        present(playerViewController!, animated: true) {
            player.play()
        }
    }
    
    func shareFile(at url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    func deleteFile(at url: URL, indexPath: IndexPath) {
        let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: url)
                print("File deleted successfully.")
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } catch {
                print("Error deleting file: \(error)")
            }
    }
}
