import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../data/story_data.dart';
import '../services/audio_assistant.dart';

class ReadabilityScreen extends StatefulWidget {
  const ReadabilityScreen({super.key});

  @override
  State<ReadabilityScreen> createState() => _ReadabilityScreenState();
}

class _ReadabilityScreenState extends State<ReadabilityScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  File? _image;
  bool _isAnalyzing = false;
  String _extractedText = "";
  double _readabilityScore = 0.0;
  String _gradeLevel = "";
  String _writingPrompt = "";
  
  // Session State
  int _submissionCount = 0;
  int _lowScoreCount = 0;
  bool _isSessionFinished = false;
  
  @override
  void initState() {
      super.initState();
      _generatePrompt();
  }
  
  void _generatePrompt() {
      final random = Random();
      setState(() {
          _writingPrompt = StoryData.sentences[random.nextInt(StoryData.sentences.length)];
          _image = null;
          _extractedText = "";
      });
  }
  
  void _advanceSession() {
      if (_submissionCount >= 3) {
          setState(() {
              _isSessionFinished = true;
          });
      } else {
          _generatePrompt();
      }
  }

  void _resetSession() {
      setState(() {
          _submissionCount = 0;
          _lowScoreCount = 0;
          _isSessionFinished = false;
          _generatePrompt();
      });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickAndProcessImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _isAnalyzing = true;
        _extractedText = "";
      });

      final inputImage = InputImage.fromFile(_image!);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      _calculateReadability(recognizedText.text);

    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _calculateReadability(String text) {
      if (text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No text found. Please try again.")),
          );
          setState(() {
              _isAnalyzing = false;
              // Do not set _extractedText so we stay in 'Scan' mode
          });
          return;
      }

      // 1. Preprocess
      String cleanText = text.replaceAll('\n', ' ');
      
      // 2. Count Sentences (approximate by punctuation)
      int sentences = cleanText.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
      if (sentences == 0) sentences = 1;

      // 3. Count Words
      List<String> words = cleanText.split(' ').where((w) => w.trim().isNotEmpty).toList();
      int wordCount = words.length;
      if (wordCount == 0) wordCount = 1;

      // 4. Count Syllables (Heuristic)
      int syllables = 0;
      for (String word in words) {
          syllables += _estimateSyllables(word);
      }

      // 5. Flesch Reading Ease Formula
      // Score = 206.835 - (1.015 * ASL) - (84.6 * ASW)
      // ASL = Average Sentence Length (Words / Sentences)
      // ASW = Average Syllables per Word (Syllables / Words)
      double asl = wordCount / sentences;
      double asw = syllables / wordCount;

      double score = 206.835 - (1.015 * asl) - (84.6 * asw);
      
      // Normalize to 0-100 range roughly
      // Standard Flesch: 100 (Easy) -> 0 (Expert)
      // We want percent representation? Or just raw score?
      // Let's clamp it.
      score = max(0, min(100, score));

      // 6. Meaningfulness Check
      int validWords = 0;
      final Set<String> vocab = StoryData.getVocabulary();
      
      for (String word in words) {
          String cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
          if (vocab.contains(cleanWord) || 
              (cleanWord.length > 2 && RegExp(r'[aeiouy]').hasMatch(cleanWord))) { 
              validWords++;
          }
      }

      double validityRatio = wordCount > 0 ? validWords / wordCount : 0;
      bool isMeaningless = validityRatio < 0.4; // Less than 40% valid words

      if (isMeaningless) {
          score = 30.0;
      }

      String grade = "";
      if (score >= 90) grade = "Very Easy";
      else if (score >= 80) grade = "Easy";
      else if (score >= 70) grade = "Fairly Easy";
      else if (score >= 60) grade = "Standard";
      else if (score >= 50) grade = "Fairly Difficult";
      else if (score >= 30) grade = "Difficult";
      else grade = "Very Difficult";

      // Override grade for meaningless text
      if (isMeaningless) {
          grade = "Unclear Text";
      }

      setState(() {
          _extractedText = cleanText;
          _readabilityScore = score;
          _gradeLevel = grade;
          
          _submissionCount++;
          if (score < 30) {
              _lowScoreCount++;
          }
          
          // Audio Feedback
          AudioAssistant().processHandwriting(score);
      });
  }

  int _estimateSyllables(String word) {
    word = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (word.isEmpty) return 0;
    if (word.length <= 3) return 1;

    // Remove silent 'e' at end
    if (word.endsWith('e')) {
        word = word.substring(0, word.length - 1);
    }

    // Count vowel groups
    final matches = RegExp(r'[aeiouy]+').allMatches(word);
    return max(1, matches.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Readability Analyzer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isSessionFinished ? _buildFinalSummary() : _buildActiveSession(),
      ),
    );
  }
  
  Widget _buildActiveSession() {
      return Column(
          children: [
             Text("Challenge ${_submissionCount + 1} / 3", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
             const SizedBox(height: 20),
             
            // Prompt Card
            Card(
                color: Colors.orange.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        children: [
                            const Text("✍️ Writing Challenge", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                            const SizedBox(height: 10),
                            Text(
                                '"$_writingPrompt"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            const Text("Write this down on paper and scan it!", style: TextStyle(color: Colors.grey)),
                        ],
                    ),
                ),
            ),

            const SizedBox(height: 20),

            // Image Preview Area
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400)
              ),
              child: _image == null 
                ? const Center(child: Icon(Icons.camera_alt, size: 60, color: Colors.grey))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
            ),
            
            const SizedBox(height: 20),

            // Action Button
            if (_extractedText.isEmpty)
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickAndProcessImage,
                  icon: _isAnalyzing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera),
                  label: Text(_image == null ? "Scan Text" : "Retake Photo"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                )
            else
                ElevatedButton.icon(
                  onPressed: _advanceSession,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_submissionCount >= 3 ? "See Results" : "Next Challenge"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),


            const SizedBox(height: 30),

            // Results
            if (_extractedText.isNotEmpty)
             Card(
               elevation: 4,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   children: [
                     const Text("Readability Score", style: TextStyle(fontSize: 18, color: Colors.grey)),
                     Text(
                       "${_readabilityScore.toStringAsFixed(1)}%", 
                       style: TextStyle(
                         fontSize: 48, 
                         fontWeight: FontWeight.bold,
                         color: _readabilityScore > 60 ? Colors.green : (_readabilityScore > 40 ? Colors.orange : Colors.red)
                       )
                     ),
                     Text(_gradeLevel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                     
                     const Divider(height: 30),
                     
                     const Align(alignment: Alignment.centerLeft, child: Text("Extracted Text:", style: TextStyle(fontWeight: FontWeight.bold))),
                     const SizedBox(height: 8),
                     Container(
                       height: 100,
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                       child: SingleChildScrollView(
                         child: Text(_extractedText, style: const TextStyle(fontSize: 14)),
                       ),
                     )
                   ],
                 ),
               ),
             )
          ],
      );
  }

  Widget _buildFinalSummary() {
      bool needsPractice = _lowScoreCount >= 2;
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                   Icon(
                       needsPractice ? Icons.sentiment_dissatisfied : Icons.sentiment_very_satisfied,
                       size: 80,
                       color: needsPractice ? Colors.red : Colors.green,
                   ),
                   const SizedBox(height: 20),
                   Text(
                       needsPractice ? "Practice More!" : "Great Job!",
                       style: TextStyle(
                           fontSize: 32, 
                           fontWeight: FontWeight.bold,
                           color: needsPractice ? Colors.red : Colors.green
                       ),
                   ),
                   const SizedBox(height: 10),
                   Text(
                       needsPractice 
                        ? "You had $_lowScoreCount low scores.\nKeep writing and try again!" 
                        : "You completed the writing challenge!\nKeep up the good work!",
                       textAlign: TextAlign.center,
                       style: const TextStyle(fontSize: 18, color: Colors.grey),
                   ),
                   const SizedBox(height: 40),
                   ElevatedButton(
                       onPressed: _resetSession,
                       style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                       child: const Text("Start New Session"),
                   )
              ],
          ),
      );
  }
}
