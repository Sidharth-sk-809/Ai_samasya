class StoryData {
  static const List<String> sentences = [
      // Scene 1: Start (Sentences 0-2)
      "Once a hare made fun of a tortoise",
      "The tortoise asked for a race to win",
      "They stood at the start line together",
      
      // Scene 2: Bunny Run (Sentences 3-5)
      "The hare ran very fast ahead",
      "He left the tortoise far behind him",
      "The hare thought he would win easily",
      
      // Scene 3: Bunny Sleep (Sentences 6-8)
      "The hare stopped to eat a carrot",
      "He felt tired and closed his eyes",
      "Soon the hare fell fast asleep there",
      
      // Scene 4: Turtle Walk (Sentences 9-11)
      "The tortoise walked slowly but steady",
      "He did not stop to rest or play",
      "He passed the sleeping hare quietly",
      
      // Scene 5: Finish (Sentences 12-14)
      "The tortoise reached the finish line first",
      "The hare woke up and ran fast",
      "But the tortoise won the big race"
  ];
  static const List<String> _commonWords = [
    "i", "a", "an", "the", "in", "on", "at", "to", "for", "of", "and", "but", "or", "so", 
    "is", "am", "are", "was", "were", "be", "been", "has", "have", "had", "do", "does", "did",
    "can", "could", "will", "would", "shall", "should", "may", "might", "must",
    "he", "she", "it", "they", "we", "you", "my", "your", "his", "her", "its", "our", "their",
    "this", "that", "these", "those", "here", "there", "where", "when", "how", "why", "who", "what"
  ];

  static Set<String> getVocabulary() {
      final Set<String> vocab = {};
      
      // Add story words
      for (String sentence in sentences) {
          final words = sentence.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
          vocab.addAll(words);
      }
      
      // Add common words
      vocab.addAll(_commonWords);
      
      return vocab;
  }
}
