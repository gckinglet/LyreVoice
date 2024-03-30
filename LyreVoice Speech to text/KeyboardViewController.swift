// KeyboardViewController.swift

import UIKit
import AVFoundation

class KeyboardViewController: UIInputViewController {
    
    @IBOutlet var nextKeyboardButton: UIButton!
    var microphoneButton: UIButton!
    
    var heightConstraint: NSLayoutConstraint?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Calculate the desired height as half of the standard keyboard height
        let desiredHeight: CGFloat = 105 // Standard keyboard height is around 432 points
        
        // Check if the height constraint already exists
        if let constraint = heightConstraint {
            // Constraint exists, just update the constant
            constraint.constant = desiredHeight
        } else {
            // Constraint does not exist, create and activate it
            let newConstraint = view.heightAnchor.constraint(equalToConstant: desiredHeight)
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
        let notificationName = "com.npcase.lyrevoice.startRecording"
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(notificationName as CFString), nil, nil, true)
    }
    
    func stopRecording() {
        let notificationName = "com.npcase.lyrevoice.stopRecording"
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(notificationName as CFString), nil, nil, true)

    }
    
    func insertTranscribedText(_ text: String) {
        // Inserts the given text at the current insertion point.
        (textDocumentProxy as UIKeyInput).insertText(text)
    }
    

}
