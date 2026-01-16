import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as model;
import '../services/audio_assistant.dart';

class NumberQuestScreen extends StatefulWidget {
  const NumberQuestScreen({super.key});

  @override
  State<NumberQuestScreen> createState() => _NumberQuestScreenState();
}

class _NumberQuestScreenState extends State<NumberQuestScreen> with TickerProviderStateMixin {
  final Random _random = Random();
  
  // Digital Ink State
  final model.DigitalInkRecognizerModelManager _modelManager = model.DigitalInkRecognizerModelManager();
  late model.DigitalInkRecognizer _recognizer;
  final model.Ink _ink = model.Ink();
  List<model.StrokePoint> _currentStroke = [];
  
  // Canvas Visualization State
  List<List<Offset>> _drawnLines = []; 
  List<Offset> _currentLine = [];

  int _num1 = 0;
  int _num2 = 0;
  int _sum = 0;
  
  bool _isSuccess = false;
  bool _isChecking = false;
  bool _isModelDownloaded = false;
  String _statusMessage = "Loading Hero AI...";

  // Animation Controllers for Floating Heroes
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _initDigitalInk();
    _generateProblem(firstTime: true);
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  Future<void> _initDigitalInk() async {
      // Use 'en' model for basic alphanumeric
      const String modelTag = 'en'; 
      
      _recognizer = model.DigitalInkRecognizer(languageCode: modelTag);
      
      try {
          bool isDownloaded = await _modelManager.isModelDownloaded(modelTag);
          if (!isDownloaded) {
              setState(() => _statusMessage = "Powering up AI...");
              await _modelManager.downloadModel(modelTag);
          }
          
          setState(() {
              _isModelDownloaded = true;
              _statusMessage = "";
          });
      } catch (e) {
          debugPrint("Model Error: $e");
          setState(() => _statusMessage = "AI Needs Signal!");
      }
  }

  void _generateProblem({bool firstTime = false}) {
    setState(() {
      if (firstTime) {
          _num1 = 2;
          _num2 = 3;
      } else {
          _num1 = _random.nextInt(4) + 1; // 1-4
          _num2 = _random.nextInt(5) + 1; // 1-5
      }
      _sum = _num1 + _num2;
      _isSuccess = false;
      _isChecking = false;
      _ink.strokes.clear();
      _drawnLines.clear();
      _currentLine.clear();
    });
  }

  Future<void> _checkHandwriting() async {
    if (_ink.strokes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Draw the number first, Hero!")));
        return;
    }
    
    if (!_isModelDownloaded) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI is still charging up...")));
        return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
        final List<model.RecognitionCandidate> candidates = await _recognizer.recognize(_ink);
        
        String bestMatch = "";
        if (candidates.isNotEmpty) {
            bestMatch = candidates.first.text;
        }

        int? answer = int.tryParse(bestMatch);
        // Fallback checks
        if (answer == null && candidates.length > 1) {
             for (var c in candidates) {
                 int? val = int.tryParse(c.text);
                 if (val != null) {
                     answer = val;
                     bestMatch = c.text;
                     break;
                 }
             }
        }
        
        bool isCorrect = (answer != null && answer == _sum);
        
        await AudioAssistant().taskFeedback(
            success: isCorrect, 
            taskName: isCorrect ? "Math Mission" : null
        );

        if (isCorrect) {
            setState(() {
                _isSuccess = true;
            });
            Future.delayed(const Duration(seconds: 4), () {
                if (mounted) _generateProblem();
            });
        } else {
             String feedback = bestMatch.isEmpty ? "Alien scribbles?" : "I saw '$bestMatch'.";
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$feedback Try again, Hero!")));
             Future.delayed(const Duration(seconds: 2), () {
                 if (mounted) {
                     _clearPad();
                     setState(() => _isChecking = false);
                 }
             });
        }

    } catch (e) {
        debugPrint("Error checking handwriting: $e");
        setState(() => _isChecking = false);
    }
  }
  
  void _clearPad() {
      setState(() {
          _ink.strokes.clear();
          _drawnLines.clear();
          _currentLine.clear();
          _isChecking = false;
      });
  }

  @override
  void dispose() {
    _recognizer.close();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Number Quest", style: TextStyle(fontFamily: 'Rumpelstiltskin', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4)])),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
            children: [
                // 1. Gradient Background
                Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Vibrant Blue/Cyan
                        )
                    ),
                ),
                
                // 2. Floating Heroes (Animated Background)
                AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                        return Stack(
                            children: [
                                Positioned(
                                    top: 100 + (_floatController.value * 20),
                                    left: 40,
                                    child: const Text("🦸", style: TextStyle(fontSize: 50)),
                                ),
                                Positioned(
                                    top: 250 - (_floatController.value * 30),
                                    right: 30,
                                    child: const Text("🚀", style: TextStyle(fontSize: 60)),
                                ),
                                Positioned(
                                    bottom: 150 + (_floatController.value * 25),
                                    left: 20,
                                    child: const Text("⭐", style: TextStyle(fontSize: 40)),
                                ),
                                Positioned(
                                    bottom: 50 - (_floatController.value * 15),
                                    right: 80,
                                    child: const Text("🦸‍♀️", style: TextStyle(fontSize: 55)),
                                )
                            ],
                        );
                    }
                ),

                // 3. Main Content
                SafeArea(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                        child: Column(
                            children: [
                                const SizedBox(height: 10),
                                
                                // Question Card
                                Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                                        ]
                                    ),
                                    child: Column(
                                        children: [
                                            Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                    _buildAppleGroup(_num1),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      child: Text("+", style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.orange.shade600)),
                                                    ),
                                                    _buildAppleGroup(_num2),
                                                ],
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                                decoration: BoxDecoration(
                                                    color: Colors.orange.shade100,
                                                    borderRadius: BorderRadius.circular(20)
                                                ),
                                                child: Text("=", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
                                            ),
                                        ],
                                    ),
                                ),
                                
                                const SizedBox(height: 30),

                                // Success or Input Area
                                if (_isSuccess)
                                    Column(
                                        children: [
                                            ScaleTransition(
                                                scale: _floatController,
                                                child: _buildAppleGroup(_sum, scale: 1.5)
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                                padding: const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                    color: Colors.green.shade100,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: Colors.green, width: 3)
                                                ),
                                                child: Column(
                                                    children: [
                                                        Text("$_sum", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.green.shade800)),
                                                        const Text("AMAZING!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                                                    ],
                                                )
                                            )
                                        ],
                                    )
                                else
                                    Column(
                                        children: [
                                            if (_statusMessage.isNotEmpty)
                                                Padding(
                                                    padding: const EdgeInsets.only(bottom: 15),
                                                    child: Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, backgroundColor: Colors.black26)),
                                                ),
                                            const Text("Draw the Number:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1,1))])),
                                            const SizedBox(height: 15),
                                            
                                            // DRAWING CANVAS (Hero Pad)
                                            Container(
                                                width: 300,
                                                height: 300,
                                                decoration: BoxDecoration(
                                                    color:  const Color(0xFFFFF9C4), // Light Yellow Paper
                                                    border: Border.all(color: const Color(0xFFFF6F00), width: 8), // Orange Border
                                                    borderRadius: BorderRadius.circular(30),
                                                    boxShadow: [
                                                        const BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))
                                                    ]
                                                ),
                                                clipBehavior: Clip.hardEdge,
                                                child: Stack(
                                                    children: [
                                                        // Subtle grid lines?
                                                        CustomPaint(size: const Size(300,300), painter: GridPainter()),
                                                        GestureDetector(
                                                            onPanStart: (details) {
                                                                _currentStroke = [];
                                                                _currentLine = [];
                                                                model.StrokePoint point = model.StrokePoint(
                                                                    x: details.localPosition.dx,
                                                                    y: details.localPosition.dy,
                                                                    t: DateTime.now().millisecondsSinceEpoch,
                                                                );
                                                                _currentStroke.add(point);
                                                                _currentLine.add(details.localPosition);
                                                                setState(() {}); 
                                                            },
                                                            onPanUpdate: (details) {
                                                                model.StrokePoint point = model.StrokePoint(
                                                                    x: details.localPosition.dx,
                                                                    y: details.localPosition.dy,
                                                                    t: DateTime.now().millisecondsSinceEpoch,
                                                                );
                                                                _currentStroke.add(point);
                                                                _currentLine.add(details.localPosition);
                                                                setState(() {}); 
                                                            },
                                                            onPanEnd: (details) {
                                                                final stroke = model.Stroke();
                                                                stroke.points.addAll(_currentStroke);
                                                                _ink.strokes.add(stroke);
                                                                _drawnLines.add(List.from(_currentLine));
                                                                _currentLine = [];
                                                                setState(() {});
                                                            },
                                                            child: CustomPaint(
                                                                painter: DigitalInkPainter(_drawnLines, _currentLine),
                                                                size: const Size(300, 300),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                            
                                            const SizedBox(height: 30),
                                            
                                            // Controls (Big Candy Buttons)
                                            Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                    ElevatedButton.icon(
                                                        onPressed: _clearPad,
                                                        icon: const Icon(Icons.refresh, size: 30),
                                                        label: const Text("Clear", style: TextStyle(fontSize: 20)),
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFFFF5252), // Red
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                            elevation: 5,
                                                        ),
                                                    ),
                                                    const SizedBox(width: 20),
                                                    ElevatedButton.icon(
                                                        onPressed: _isChecking ? null : _checkHandwriting,
                                                        icon: _isChecking ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.check_circle, size: 30),
                                                        label: Text(_isChecking ? "Checking..." : "GO!", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF00E676), // Green
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                            elevation: 8,
                                                            shadowColor: Colors.greenAccent
                                                        ),
                                                    )
                                                ],
                                            )
                                        ],
                                    )
                            ],
                        ),
                    ),
                )
            ],
        ),
    );
  }

  Widget _buildAppleGroup(int count, {double scale = 1.0}) {
      return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade100, width: 2)
          ),
          child: Column(
              children: [
                  Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: List.generate(count, (index) => 
                          TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 500 + (index * 200)),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                  return Transform.scale(
                                      scale: value,
                                      child: Text("🍎", style: TextStyle(fontSize: 36 * scale))
                                  );
                              },
                          )
                      ),
                  ),
                  const SizedBox(height: 5),
                  Text("$count", style: TextStyle(fontSize: 24 * scale, fontWeight: FontWeight.bold, color: Colors.purple.shade700))
              ],
          ),
      );
  }
}

class GridPainter extends CustomPainter {
    @override
    void paint(Canvas canvas, Size size) {
        Paint paint = Paint()..color = Colors.blue.withOpacity(0.1)..strokeWidth = 1;
        for (double i = 0; i < size.width; i+=40) {
            canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
        }
        for (double i = 0; i < size.height; i+=40) {
            canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
        }
    }
    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DigitalInkPainter extends CustomPainter {
  final List<List<Offset>> lines;
  final List<Offset> currentLine;

  DigitalInkPainter(this.lines, this.currentLine);

  @override
  void paint(Canvas canvas, Size size) {
    // Fun color for the ink? No, black is best for recognition contrast.
    // We can use Very Dark Blue.
    Paint paint = Paint()
      ..color = const Color(0xFF1A237E) // Indigo 900
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;

    for (var line in lines) {
        _drawLine(canvas, line, paint);
    }
    _drawLine(canvas, currentLine, paint);
  }
  
  void _drawLine(Canvas canvas, List<Offset> points, Paint paint) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
