 
/// reference  https://github.com/lixing123/ExtAudioFileConverter/

import UIKit
import AVFoundation
import Combine
import MobileCoreServices
import FYPhoto


class ViewController: UIViewController {
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var disposable = Set<AnyCancellable>()
    var pickerConfig = FYPhotoPickerConfiguration()
    var inputURL: URL?
    var customFileName: String?
    
    
    @IBOutlet weak var convertButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.numberOfLines = 0
        statusLabel.lineBreakMode = .byWordWrapping
        
        configurePicker()
        
    }
    
    func configurePicker() {
        pickerConfig.selectionLimit = 0
        pickerConfig.supportCamera = true
        pickerConfig.mediaFilter = [.image, .video]

        let colorConfig = FYColorConfiguration()
        colorConfig.topBarColor = FYColorConfiguration.BarColor(itemTintColor: .red,
                                                                itemDisableColor: .gray,
                                                                itemBackgroundColor: .black,
                                                                backgroundColor: .blue)

        pickerConfig.colorConfiguration = colorConfig

        // Configure video-related settings
        pickerConfig.compressedQuality = .mediumQuality
        pickerConfig.maximumVideoMemorySize = 40 // MB
        pickerConfig.maximumVideoDuration = 60 // Secs
    }
    
    @IBAction func convertAction(_ sender: UIButton) {
        
        self.statusLabel.text = "Converting..."

            let input = inputURL!
            let converter = MP3Converter()
            convertButton.isEnabled = false

            // Create an alert controller with a text field for the file name
            let alertController = UIAlertController(title: "Save File", message: "Enter a file name", preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "File Name"
            }

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
                   // Set a default value for customFileName if the user cancels
                self!.statusLabel.text = "Convertion Cancelled!!!"
               }))

            alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
                guard let fileName = alertController.textFields?.first?.text else {

                    return
                }

                // Update the customFileName property with the user-provided file name
                self?.customFileName = fileName

                DispatchQueue.global(qos: .userInteractive).async {
                    let output = self?.getDocumentsDirectory().appendingPathComponent("\(fileName).mp3") ?? URL(fileURLWithPath: "")

                    converter.convert(input: input, output: output)
                        .receive(on: DispatchQueue.global())
                        .sink(receiveCompletion: { result in
                            DispatchQueue.main.async {
                                if case .failure(let error) = result {
                                    self?.statusLabel.text = "Conversion failed: \n\(error.localizedDescription)"
                                    self?.convertButton.isEnabled = true
                                }
                            }
                        }, receiveValue: { result in
                            DispatchQueue.main.async {
                                self?.statusLabel.text = "File saved as \(fileName).mp3 in \nthe documents directory."
                            }
                        }).store(in: &(self!.disposable))
                }
            }))

            self.present(alertController, animated: true, completion: nil)

    }
    
    
    @IBAction func selectVideoButtonTapped(_ sender: UIButton) {
        convertButton.isEnabled = true
        self.statusLabel.text = "[Status]"
        let photoPickerVC = PhotoPickerViewController(configuration: pickerConfig)

//        photoPickerVC.selectedPhotos = { [weak self] images in
//            // Handle selected photos
//        }

        photoPickerVC.selectedVideo = { [weak self] selectedResult in
            switch selectedResult {
            case .success(let video):
                self?.inputURL = video.url
            case .failure(let error):
                print("Selected video error: \(error)")
            }
        }

        photoPickerVC.modalPresentationStyle = .fullScreen
        self.present(photoPickerVC, animated: true, completion: nil)
    }
    
    @IBAction func goToListClicked(_ sender: UIButton) {
        
        performSegue(withIdentifier: "gotToMp3List", sender: nil)

    }
}
