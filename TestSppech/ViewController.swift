//
//  ViewController.swift
//  TestSppech
//
//  Created by steven on 2020/11/27.
//  Copyright © 2020 steven. All rights reserved.
//

import UIKit
import Speech
class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh_TW"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        microphoneButton.isEnabled = false
        speechRecognizer.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("用戶拒絕接受語音識別")
                
            case .restricted:
                isButtonEnabled = false
                print("語音識別功能沒有經過認可")
                
            case .notDetermined:
                isButtonEnabled = false
                print("當前設備不能語音識別")
                
            @unknown default:
                print("錯誤")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }

    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }

    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)  // 音頻輸入或輸出的測量
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)  // 停止其他音樂
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        // SFSpeechAudioBufferRecognitionRequest
        // SFSpeechURLRecognitionRequest
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode 
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                print(result?.bestTranscription.formattedString)
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("錯誤，audioEngine無法啟動。")
        }
        
        textView.text = "說點什麼，我在聽！"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}

