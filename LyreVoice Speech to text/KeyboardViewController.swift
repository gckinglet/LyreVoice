//
//  KeyboardViewController.swift
//  LyreVoice Speech to text
//
//  Created by Weining Liu on 3/2/24.
//

import UIKit
import AVFoundation

class KeyboardViewController: UIInputViewController, AVAudioRecorderDelegate {

    @IBOutlet var nextKeyboardButton: UIButton!
    var microphoneButton: UIButton!
    
    var audioRecorder: AVAudioRecorder?
    var audioFileURL: URL?
    var heightConstraint: NSLayoutConstraint?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Calculate the maximum height as 30% of the screen height
        let maxHeight = UIScreen.main.bounds.size.height * 0.3
        
        // Check if the height constraint already exists
        if let constraint = heightConstraint {
            // Constraint exists, just update the constant
            constraint.constant = maxHeight
        } else {
            // Constraint does not exist, create and activate it
            let newConstraint = view.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)
            newConstraint.isActive = true
            heightConstraint = newConstraint // Keep a reference to the newly created constraint
        }
    }

    
    override func viewDidLoad() {
           super.viewDidLoad()
           
           // Perform custom UI setup here
           setupNextKeyboardButton()
           setupMicrophoneButton()
       }
       
       private func setupNextKeyboardButton() {
           self.nextKeyboardButton = UIButton(type: .system)
           self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
           self.nextKeyboardButton.sizeToFit()
           self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
           self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
           self.view.addSubview(self.nextKeyboardButton)
           self.nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
           self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
       }

       private func setupMicrophoneButton() {
           // Initialize the microphone button
           microphoneButton = UIButton(type: .custom)
           // Assuming you have a microphone image in your assets named "microphone"
           microphoneButton.setImage(UIImage(named: "microphone"), for: .normal)
           microphoneButton.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(microphoneButton)
           
           // Set constraints to position the microphone button in the center
           microphoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
           microphoneButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
           microphoneButton.widthAnchor.constraint(equalToConstant: 80).isActive = true // Adjust size as needed
           microphoneButton.heightAnchor.constraint(equalToConstant: 80).isActive = true // Adjust size as needed
           
           // Add action for microphone button
           let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
           microphoneButton.addGestureRecognizer(longPressRecognizer)
           
           // Tap recognizer for no action on tap
           let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
           microphoneButton.addGestureRecognizer(tapRecognizer)
       }
    
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            microphoneButton.setImage(UIImage(named: "recording"), for: .normal)
            startRecording()
        } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
            stopRecording()
            convertRecordingToText()
            microphoneButton.setImage(UIImage(named: "microphone"), for: .normal)
        }
    }
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        // Intentionally do nothing on tap
    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }

    func startRecording() {
           AVAudioSession.sharedInstance().requestRecordPermission {  [weak self] granted in
               guard let self = self else {
                   return
               }
               if granted {
                   do {
                       try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
                       try AVAudioSession.sharedInstance().setActive(true)
                       
                       let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                       let fileName = "audioRecording.m4a"
                       self.audioFileURL = paths[0].appendingPathComponent(fileName)
                       
                       let settings = [
                           AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                           AVSampleRateKey: 48000,
                           AVNumberOfChannelsKey: 1,
                           AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                       ]
                       
                       self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL!, settings: settings)
                       self.audioRecorder?.delegate = self
                       self.audioRecorder?.record()
                   } catch {
                       print("Failed to start recording: \(error)")
                   }
               } else {
                   print("Permission to record was not granted")
               }
           }
       }
       
       func stopRecording() {
           audioRecorder?.stop()
           try? AVAudioSession.sharedInstance().setActive(false)
       }
       
       func convertRecordingToText() {
           guard let audioFileURL = self.audioFileURL else { return }
               // Create the URL for the POST request
               let url = URL(string: "https://l0v1ghq9z0.execute-api.us-east-1.amazonaws.com/dev/v1/audio/transcriptions")!
               var request = URLRequest(url: url)
               request.httpMethod = "POST"
               request.addValue("UIdXL28W213xMhPwAuKOr4PZhV41Fv4h3zMu5gvN", forHTTPHeaderField: "x-api-key")
               
               // Generate boundary string using a unique per-app string
               let boundary = "Boundary-\(UUID().uuidString)"
               request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
               
               var data = Data()
               // Function to append string as Data
               func append(_ string: String) {
                   if let dataFromString = string.data(using: .utf8) {
                       data.append(dataFromString)
                   }
               }
                   
               // Append audio file
               append("--\(boundary)\r\n")
               append("Content-Disposition: form-data; name=\"file\"; filename=\"audioRecording.m4a\"\r\n")
               append("Content-Type: audio/m4a\r\n\r\n")
               do {
                   let audioData = try Data(contentsOf: audioFileURL)
                   data.append(audioData)
                   append("\r\n")
               } catch {
                   print("Error loading audio file data: \(error)")
                   return
               }
               
               // Append additional parameters
               append("--\(boundary)\r\n")
               append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
               append("whisper-1\r\n")
               
               append("--\(boundary)\r\n")
               append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
               append("你好, 欢迎你来. 我同时讲中文和English.\r\n")
               
               // End of multipart/form-data
               append("--\(boundary)--\r\n")
               
               request.httpBody = data
               
               // Perform the request
               let session = URLSession.shared
               let task = session.dataTask(with: request) { data, response, error in
                   guard let data = data, error == nil else {
                       print("Error during URLSession data task: \(error?.localizedDescription ?? "Unknown error")")
                       return
                   }
                   
                   if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                       do {
                           if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let transcribedText = jsonResult["text"] as? String {
                               DispatchQueue.main.async {
                                   print("Transcription Success: \(transcribedText)")
                                   self.insertTranscribedText(transcribedText)
                               }
                           } else {
                               print("Failed to decode JSON response")
                           }
                       } catch {
                           print("Error parsing JSON response: \(error)")
                       }
                   } else {
                       print("HTTP Error: \(response.debugDescription)")
                   }
               }
               task.resume()
           }

    func insertTranscribedText(_ text: String) {
           // Inserts the given text at the current insertion point.
           (textDocumentProxy as UIKeyInput).insertText(text)
       }
}
