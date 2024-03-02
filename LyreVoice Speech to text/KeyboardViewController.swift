//
//  KeyboardViewController.swift
//  LyreVoice Speech to text
//
//  Created by Weining Liu on 3/2/24.
//

import UIKit

class KeyboardViewController: UIInputViewController {

    @IBOutlet var nextKeyboardButton: UIButton!
    var microphoneButton: UIButton!
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
        // Ensure that the view's height is about 1/4 of the screen height

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
           microphoneButton.addTarget(self, action: #selector(microphoneButtonTapped), for: .touchUpInside)
       }
    
    @objc func microphoneButtonTapped() {
        // Handle microphone button tap event
        print("Microphone button tapped")
        // Implement your speech-to-text functionality here
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

        
}
