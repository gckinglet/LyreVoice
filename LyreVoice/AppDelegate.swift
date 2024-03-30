// AppDelegate.swift host app

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioRecorderDelegate{
    
    var window: UIWindow?
    var audioRecorder: AVAudioRecorder?
    var audioFileURL: URL?
    var fileName: String?
    var recordingStartTime: Date?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Print the received URL
        print("Received URL: \(url)")
        
        // Determine who sent the URL
        if let sourceApplication = options[.sourceApplication] as? String {
            print("Source application: \(sourceApplication)")
        } else {
            print("Source application not available")
        }
        
        // Check if the URL scheme matches your custom scheme
        if url.scheme == "LyreVoice" {
            // Handle the custom URL
            if url.host == "recorder" {
                if let query = url.query {
                    print("URL query: \(query)")
                    
                    let components = query.components(separatedBy: "=")
                    if components.count == 2 {
                        let key = components[0]
                        let value = components[1]
                        
                        print("Query key: \(key)")
                        print("Query value: \(value)")
                        
                        if key == "recording" {
                            if value == "start" {
                                print("Starting background recording")
                                startBackgroundRecording()
                            } else if value == "stop" {
                                print("Stopping background recording")
                                stopBackgroundRecording()
                                convertRecordingToText()
                            } else {
                                print("Invalid recording action")
                            }
                        } else {
                            print("Invalid query key")
                        }
                    } else {
                        print("Invalid query format")
                    }
                } else {
                    print("URL query not available")
                }
            } else if url.host == "activate" {
                DispatchQueue.main.async {
                    self.showActivationAlert()
                }
                return true
            } else {
                print("Invalid URL host")
            }
            
            return true
        }
        
        print("Unhandled URL scheme")
        return false
    }
    
    private func showActivationAlert() {
        guard let rootViewController = window?.rootViewController else {
            print("RootViewController not found.")
            return
        }

        let alert = UIAlertController(title: "Microphone Access Needed",
                                      message: "Due to iOS constraints, LyreVoice app has to run in the background in order to access the microphone. Click okay to allow LyreVoice to access the microphone in the background.",
                                      preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay", style: .default) { _ in
            // Start recording as per your app's functionality
            self.startBackgroundRecording()

            // Switch back to the keyboard extension or the previous app
            // Note: iOS does not allow programmatically switching to another app without user interaction.
            // This step assumes the user navigates back or you have a specific method in place.
        }
        
        alert.addAction(okayAction)
        rootViewController.present(alert, animated: true, completion: nil)
    }

    
    func startBackgroundRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                print("Recording permission granted")
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    self.fileName = "audiofile.wav"
                    self.audioFileURL = paths[0].appendingPathComponent(self.fileName!)
                    
                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    self.audioRecorder = try AVAudioRecorder(url: self.audioFileURL!, settings: settings)
                    self.audioRecorder?.delegate = self
                    self.recordingStartTime = Date()
                    if self.audioRecorder?.prepareToRecord() == true {
                        if self.audioRecorder?.record() == true {
                            print("Audio recording started at: \(self.recordingStartTime ?? Date())")
                        } else {
                            print("Failed to start audio recording")
                        }
                    } else {
                        print("Failed to prepare audio recorder")
                    }
                } catch {
                    print("Failed to start recording: \(error)")
                }
            } else {
                print("Permission to record was not granted")
            }
        }
    }
    
    func stopBackgroundRecording() {
        audioRecorder?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        print("Audio recording stopped at: \(Date())")
    }
    
    func convertRecordingToText() {
        print("Convert recording to text")
        guard let audioFileURL = self.audioFileURL else {
            print("Audio file URL is nil")
            return
        }
        
        // Print audio file size before sending
        if let audioFileAttributes = try? FileManager.default.attributesOfItem(atPath: audioFileURL.path) {
            let audioFileSize = audioFileAttributes[FileAttributeKey.size] as? Int64 ?? 0
            let audioFileModificationDate = audioFileAttributes[FileAttributeKey.modificationDate] as? Date ?? Date()
            print("Audio file size before sending: \(audioFileSize) bytes")
            print("Audio file modification timestamp: \(audioFileModificationDate)")
        } else {
            print("Failed to get audio file size before sending")
        }
        
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
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName ?? "audiofile.wav")\"\r\n")
        append("Content-Type: audio/wav\r\n\r\n")
        do {
            let audioData = try Data(contentsOf: audioFileURL)
            print("Audio data size before appending to HTTP body: \(audioData.count) bytes")
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
        append("你好, 我会在一句话里同时用中文和English. Please transcribe audio to the original languages 并加上标点符号. \r\n")
        
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
                            // Pass the transcribed text back to the custom keyboard extension
                            // You can use a shared container or custom URL scheme for this
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
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Audio recording finished. Success: \(flag)")
        if flag {
            convertRecordingToText()
        }
    }
    
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recording encode error occurred: \(error.localizedDescription)")
        } else {
            print("Audio recording encode error occurred without specific error details")
        }
        
        // Handle the encode error (e.g., stop recording, display an error message, etc.)
        stopBackgroundRecording()
        // Display an error message to the user or perform any necessary error handling
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.npcase.LyreVoice.sharedcontainer")
        sharedDefaults?.set(true, forKey: "HostAppIsActive")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.npcase.LyreVoice.sharedcontainer")
        sharedDefaults?.set(false, forKey: "HostAppIsActive")
    }
    
    
}
