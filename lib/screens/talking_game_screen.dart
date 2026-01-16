import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/speech_service.dart';
import '../data/story_data.dart';
import '../services/audio_assistant.dart';

class TalkingGameScreen extends StatefulWidget {
  const TalkingGameScreen({super.key});

  @override
  State<TalkingGameScreen> createState() => _TalkingGameScreenState();
}

class _TalkingGameScreenState extends State<TalkingGameScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechService _speechService = SpeechService();
  
  // Data: "The Tortoise and the Hare" (15 Sentences)
  // Data: "The Tortoise and the Hare" (15 Sentences)
  final List<String> _sentences = StoryData.sentences;
  
  // Map index to Image Asset
  String _getImageForIndex(int index) {
      if (index < 3) return "assets/images/story_start.png";
      if (index < 6) return "assets/images/bunny_run.png";
      if (index < 9) return "assets/images/bunny_sleep.png";
      if (index < 12) return "assets/images/turtle_walk.png";
      return "assets/images/story_finish.png";
  }
  
  int _currentSentenceIndex = 0;
  List<String> _targetWords = [];
  
  // Game State
  String _recognizedText = "";
  bool _isListening = false;
  bool _waitingForNext = false;
  
  // Metrics
  int _wpm = 0;
  int _repetitions = 0;
  double _durationSeconds = 0;
  DateTime? _startTime;
  int _matchedWordIndex = 0;
  
  // Advanced Tracking
  int _lowAccuracyCount = 0; 
  static const int _alertThreshold = 10;
  static const double _minAccuracy = 0.30;

  @override
  void initState() {
    super.initState();
    _loadSentence(_currentSentenceIndex);
    _initServices();
  }

  void _loadSentence(int index) {
      if (index >= _sentences.length) {
          _currentSentenceIndex = 0; 
      } else {
          _currentSentenceIndex = index;
      }
      
      String raw = _sentences[_currentSentenceIndex];
      _targetWords = raw.split(' ')
          .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), ''))
          .toList();
      
      _resetState();
  }

  void _resetState() {
      if (mounted) {
        setState(() {
            _recognizedText = "";
            _matchedWordIndex = 0;
            _wpm = 0;
            _repetitions = 0;
            _isListening = false;
            _waitingForNext = false;
        });
      }
  }

  Future<void> _initServices() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    bool sttAvailable = await _speechService.init();
    
    if (sttAvailable) {
      _speak("Hello! Let's read a story together.");
    } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Speech recognition not available")),
            );
        }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _toggleRecording() async {
    if (_waitingForNext) return; 
    if (_isListening) {
      await _stopRecording();
    } else {
      setState(() {
        _isListening = true;
        _recognizedText = "";
        _startTime = DateTime.now();
        _repetitions = 0;
        _matchedWordIndex = 0;
        _wpm = 0;
      });
      await _speechService.startListening(onResult: (text) {
        if (!mounted) return;
        setState(() {
          _recognizedText = text;
        });
        _processLiveSpeech(text);
      });
    }
  }

  Future<void> _stopRecording() async {
    await _speechService.stop();
    if (mounted) {
        setState(() {
            _isListening = false;
        });
        _analyzeResult();
    }
  }

  void _processLiveSpeech(String currentText) {
    if (currentText.isEmpty) return;
    
    List<String> spokenWords = currentText.toLowerCase().split(' ');
    
    int tempMatchIndex = 0;
    int spokenPointer = 0;
    
    while (tempMatchIndex < _targetWords.length && spokenPointer < spokenWords.length) {
        String target = _targetWords[tempMatchIndex].toLowerCase();
        String spoken = spokenWords[spokenPointer].toLowerCase();
        
        target = target.replaceAll(RegExp(r'[^\w\s]'), '');
        spoken = spoken.replaceAll(RegExp(r'[^\w\s]'), '');

        if (spoken == target) {
            tempMatchIndex++;
            spokenPointer++;
        } else {
            spokenPointer++;
        }
    }

    if (tempMatchIndex != _matchedWordIndex) {
        if (mounted) {
            setState(() {
                _matchedWordIndex = tempMatchIndex;
            });
        }
    }

    // Auto-Stop Check
    if (_matchedWordIndex == _targetWords.length) {
        _stopRecording();
    }
  }

  void _analyzeResult() {
    if (_startTime == null) return;
    
    final duration = DateTime.now().difference(_startTime!);
    _durationSeconds = duration.inMilliseconds / 1000.0;
    
    // Clean punctuation from spoken words for analysis
    List<String> spokenWords = _recognizedText.toLowerCase().split(' ')
        .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), ''))
        .where((w) => w.isNotEmpty)
        .toList();
    
    // 1. Calculate WPM
    if (_durationSeconds > 0 && spokenWords.isNotEmpty) {
      _wpm = ((spokenWords.length / _durationSeconds) * 60).round();
    }

    // 2. Detect Repetitions
    int repetitionCount = 0;
    for (int i = 1; i < spokenWords.length; i++) {
        if (spokenWords[i].isNotEmpty && spokenWords[i] == spokenWords[i - 1]) {
            repetitionCount++;
        }
    }
    _repetitions = repetitionCount;

    // 3. Accuracy Check
    double accuracy = 0.0;
    if (_targetWords.isNotEmpty) {
        accuracy = _matchedWordIndex / _targetWords.length;
    }

    if (accuracy < _minAccuracy) {
        _lowAccuracyCount++;
    } else {
        _lowAccuracyCount = 0; 
    }
    
    _checkWarnings();

    // Feedback
    String feedback = "You read $_wpm words per minute.";
    if (accuracy >= 1.0) {
        feedback += " Perfect!";
    } else if (accuracy > 0.5) {
        feedback += " Good job!";
    } else {
        feedback += " Try again!";
    }
    
    _speak(feedback);
    
    if (mounted) {
        _scheduleNextSentence();
    }
  }
  
  void _checkWarnings() {
      if (_lowAccuracyCount > _alertThreshold) {
          showDialog(
              context: context, 
              builder: (ctx) => AlertDialog(
                  title: const Text("Parent Alert"),
                  content: const Text("Accuracy has been low for 10 consecutive attempts.\nPlease check if the reading level is appropriate."),
                  actions: [
                      TextButton(onPressed: () {
                          Navigator.pop(ctx);
                          _lowAccuracyCount = 0; 
                      }, child: const Text("OK"))
                  ],
              )
          );
      }
  }

  void _scheduleNextSentence() {
      if (!mounted) return;
      
      // Check if story is finishing
      if (_currentSentenceIndex + 1 >= _sentences.length) {
          AudioAssistant().storyFeedback(true);
      }
      
      setState(() {
          _waitingForNext = true;
      });
      
      Timer(const Duration(seconds: 5), () {
          if (mounted) {
              _loadSentence(_currentSentenceIndex + 1);
          }
      });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Story Time: Tortoise & Hare")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Progress
            Text("Part ${_currentSentenceIndex + 1} / ${_sentences.length}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),

            // Story Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                  ]
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  _getImageForIndex(_currentSentenceIndex),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, _) => const Center(child: Icon(Icons.image_not_supported, size: 50)),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Target Sentence
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200)
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Georgia'),
                  children: List.generate(_targetWords.length, (index) {
                      List<String> displayWords = _sentences[_currentSentenceIndex].split(' ');
                      String word = (index < displayWords.length) ? displayWords[index] : "";
                      
                      return TextSpan(
                          text: "$word ",
                          style: TextStyle(
                             color: index < _matchedWordIndex ? Colors.green.shade700 : Colors.black87,
                             backgroundColor: index < _matchedWordIndex ? Colors.green.shade50 : null,
                          ),
                      );
                  }),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            if (_waitingForNext)
                const LinearProgressIndicator(color: Colors.orange),

            const SizedBox(height: 20),
            
            // Real-time Feedback
            Text(
              _waitingForNext ? "Next part in 5s..." : (_isListening ? "Listening..." : "Tap to Read"),
              style: TextStyle(
                color: _isListening ? Colors.red : Colors.grey, 
                fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                fontSize: 16
              ),
            ),

            const SizedBox(height: 20),

            // Controls
            GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: _waitingForNext ? Colors.grey : (_isListening ? Colors.red : Colors.orange),
                        shape: BoxShape.circle,
                        boxShadow: [
                            BoxShadow(color: (_waitingForNext ? Colors.grey : (_isListening ? Colors.red : Colors.orange)).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                        ]
                    ),
                    child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 40,
                    ),
                ),
            ),

            const SizedBox(height: 20),
            
            // Results Panel
            if (_wpm > 0 || _repetitions > 0) 
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                        _buildStat("Speed", "$_wpm WPM", Icons.speed),
                                        _buildStat("Repeats", "$_repetitions", Icons.repeat),
                                    ],
                                ),
                            ],
                        ),
                    ),
                )
          ],
        ),
      ),
    );
  }
  
  Widget _buildStat(String label, String value, IconData icon) {
      return Column(
          children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
      );
  }
}
