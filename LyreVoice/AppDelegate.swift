// AppDelegate.swift host app

import UIKit
import AVFoundation
import SwiftUI


// Define the notification names
let startRecordingNotificationName = "com.npcase.lyrevoice.startRecording"
let stopRecordingNotificationName = "com.npcase.lyrevoice.stopRecording"

class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioRecorderDelegate{
    
    var window: UIWindow?
    var audioRecorder: AVAudioRecorder?
    var audioFileURL: URL?
    var fileName: String?
    var recordingStartTime: Date?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Register for Darwin Notifications
        registerForDarwinNotifications()
        return true
    }
 
    
    private func registerForDarwinNotifications() {
        let startNotificationName = CFNotificationName("com.npcase.lyrevoice.startRecording" as CFString)
        let stopNotificationName = CFNotificationName("com.npcase.lyrevoice.stopRecording" as CFString)
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(), AppDelegate.recordingCallback, startNotificationName.rawValue, nil, CFNotificationSuspensionBehavior.deliverImmediately)
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(), AppDelegate.recordingCallback, stopNotificationName.rawValue, nil, CFNotificationSuspensionBehavior.deliverImmediately)
    }

    static let recordingCallback: CFNotificationCallback = { center, observer, name, object, userInfo in
        guard let observer = observer else { return }
        
        let instance = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
        
        DispatchQueue.main.async {
            if let nameStr = name?.rawValue as String? {
                print("Received notification: \(nameStr)") // Debug line to log the notification name
                switch nameStr {
                case startRecordingNotificationName:
                    print("Starting background recording...")
                    instance.startBackgroundRecording()
                case stopRecordingNotificationName:
                    print("Stopping background recording...")
                    instance.stopBackgroundRecording()
                default:
                    print("Unknown notification received.")
                }
            }
        }
    }
    
    func startBackgroundRecording() {
        print("startBackgroundRecording() called.") // Additional debug line
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
        print("stopBackgroundRecording() called.") 
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
