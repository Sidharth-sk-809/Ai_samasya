import 'package:flutter_tts/flutter_tts.dart';

class AudioAssistant {
  static final AudioAssistant _instance = AudioAssistant._internal();
  factory AudioAssistant() => _instance;
  AudioAssistant._internal();
  
  late FlutterTts tts;
  
  Future init() async {
    tts = FlutterTts();
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.5); // Slower for kids
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    
    // iOS Configuration to ensure logic works even in silent mode
    await tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
        [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ]
    );
    
    await tts.awaitSpeakCompletion(true);
  }
  
  // 🔥 UNIVERSAL TASK FEEDBACK - Use for ANY task
  Future taskFeedback({required bool success, String? taskName}) async {
    String msg;
    
    if (success) {
      // SUCCESS celebrations
      msg = taskName != null 
        ? "🎉 $taskName completed! Amazing job superstar!"
        : "🎉 Fantastic! You nailed it! Superstar!";
    } else {
      // ENCOURAGEMENT for failures
      msg = taskName != null 
        ? "💪 Good effort on $taskName! Try again, you've got this!"
        : "💪 Great try! Keep going, practice makes perfect!";
    }
    
    await tts.speak(msg);
  }
  
  // Legacy support (routed through universal feedback)
  Future processHandwriting(double score) async {
    await taskFeedback(success: score > 60, taskName: "Handwriting");
  }
  
  Future storyFeedback(bool completedWell) async {
    await taskFeedback(success: completedWell, taskName: "Story Reading");
  }
}
