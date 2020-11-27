## 像Siri一樣監聽說話
### 打開info Speech權限
![](https://badgameshow.com/steven/wp-content/uploads/2020/11/Swift-語音轉文字-1.png) 

### 創建Button+TextView
![](https://badgameshow.com/steven/wp-content/uploads/2020/11/Swift-語音轉文字-2.png)

### 檢查用戶權限
```swift
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
}
```

### AVAudioSessionMode
|AudioSessionMode|兼容category|應用場景|
| ------------ | ------------ | ------------ |
|  Default | All Category  |  默認音頻會話模式 |
| VoiceChat  |  PlayAndRecord | VoIP(雙向語音通信)  |
| GameChat  | PlayAndRecord  | 遊戲錄制(Game Kit)  |
| VideoRecording  |  Record、PlayAndRecord |  錄制視頻 |
| Measurement  | Playback、Record、PlayAndRecord  | 音頻輸入或輸出的測量  |
| MoviePlayback  |  Playback |  視頻播放 |
| VideoChat  |  PlayAndRecord | 視頻通話  |
| SpokenAudio  |  Playback、SoloAmbient、PlayAndRecord、MultiRoute |  有聲讀物 |
| VoicePrompt  |  – | -  |



```swift
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
```

### Demo
![](https://i.imgur.com/JPUKxP2.gif)


### Github
[https://github.com/Bgihe/Swift-Speech](https://github.com/Bgihe/Swift-Speech "https://github.com/Bgihe/Swift-Speech")
