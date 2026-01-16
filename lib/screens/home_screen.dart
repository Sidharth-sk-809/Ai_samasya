import 'package:flutter/material.dart';
import 'talking_game_screen.dart';
import 'readability_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Reading Buddy", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Let's Read!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Story Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TalkingGameScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Cover Image
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/story_start.png',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.menu_book, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            "The Tortoise and the Hare",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              Icon(Icons.star, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text("Easy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Readability Analyzer Card
            GestureDetector(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReadabilityScreen()),
                    );
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.purple.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                            )
                        ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                        children: [
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    shape: BoxShape.circle
                                ),
                                child: const Icon(Icons.analytics, color: Colors.purple, size: 30),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                        Text("Readability Analyzer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        Text("Check reading difficulty of any text", style: TextStyle(color: Colors.grey)),
                                    ],
                                ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                    ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}
