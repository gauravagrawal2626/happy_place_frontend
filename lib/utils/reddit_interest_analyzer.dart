class UserInterest {
  final String topic;
  final int score;
  final int postCount;
  final int commentCount;
  final List<String> trophies;
  final double engagementScore;

  UserInterest({
    required this.topic,
    required this.score,
    required this.postCount,
    required this.commentCount,
    required this.trophies,
    required this.engagementScore,
  });

  @override
  String toString() {
    return 'Topic: $topic\n'
        'Score: $score\n'
        'Posts: $postCount\n'
        'Comments: $commentCount\n'
        'Trophies: ${trophies.join(", ")}\n'
        'Engagement Score: ${engagementScore.toStringAsFixed(2)}\n';
  }
}

class RedditInterestAnalyzer {
  // Trophy names that indicate strong interest in a subreddit
  static const List<String> _significantTrophies = [
    'Top Contributor',
    'Moderator',
    'Verified',
    'Gold',
    'Platinum',
    'Best Comment',
    'Best Post',
  ];

  // Calculate engagement score based on various factors
  static double _calculateEngagementScore({
    required int postCount,
    required int commentCount,
    required int totalScore,
    required List<String> trophies,
  }) {
    double score = 0.0;
    
    // Base score from content
    score += postCount * 2.0; // Posts are weighted more heavily
    score += commentCount;
    score += totalScore * 0.1; // Score from upvotes

    // Trophy bonus
    for (var trophy in trophies) {
      if (_significantTrophies.contains(trophy)) {
        score += 5.0; // Bonus points for significant trophies
      }
    }

    return score;
  }

  static List<UserInterest> extractTopInterests({
    required List<Map<String, dynamic>> posts,
    required List<Map<String, dynamic>> comments,
    required List<Map<String, dynamic>> trophies,
    int topN = 5,
  }) {
    // Group content by subreddit
    final Map<String, Map<String, dynamic>> subredditData = {};

    // Process posts
    for (var post in posts) {
      final subreddit = post['subreddit']?.toString() ?? 'unknown';
      if (subreddit == 'unknown') continue;

      subredditData.putIfAbsent(subreddit, () => {
        'score': 0,
        'postCount': 0,
        'commentCount': 0,
        'trophies': <String>[],
      });

      final score = post['score'];
      if (score != null) {
        subredditData[subreddit]!['score'] += (score is num) ? score.toInt() : 0;
      }
      subredditData[subreddit]!['postCount']++;
    }

    // Process comments
    for (var comment in comments) {
      final subreddit = comment['subreddit']?.toString() ?? 'unknown';
      if (subreddit == 'unknown') continue;

      subredditData.putIfAbsent(subreddit, () => {
        'score': 0,
        'postCount': 0,
        'commentCount': 0,
        'trophies': <String>[],
      });

      final score = comment['score'];
      if (score != null) {
        subredditData[subreddit]!['score'] += (score is num) ? score.toInt() : 0;
      }
      subredditData[subreddit]!['commentCount']++;
    }

    // Process trophies
    for (var trophy in trophies) {
      final trophyName = trophy['name']?.toString() ?? '';
      final trophyDescription = trophy['description']?.toString() ?? '';
      
      if (trophyName.isEmpty || trophyDescription.isEmpty) continue;
      
      // Try to extract subreddit from trophy description
      final subredditMatch = RegExp(r'r/(\w+)').firstMatch(trophyDescription);
      if (subredditMatch != null) {
        final subreddit = subredditMatch.group(1)!;
        if (subredditData.containsKey(subreddit)) {
          subredditData[subreddit]!['trophies'].add(trophyName);
        }
      }
    }

    // Convert to UserInterest objects and calculate engagement scores
    final interests = subredditData.entries.map((entry) {
      final data = entry.value;
      return UserInterest(
        topic: entry.key,
        score: data['score'] as int,
        postCount: data['postCount'] as int,
        commentCount: data['commentCount'] as int,
        trophies: List<String>.from(data['trophies'] as List),
        engagementScore: _calculateEngagementScore(
          postCount: data['postCount'] as int,
          commentCount: data['commentCount'] as int,
          totalScore: data['score'] as int,
          trophies: List<String>.from(data['trophies'] as List),
        ),
      );
    }).toList();

    // Sort by engagement score and return top N
    interests.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    return interests.take(topN).toList();
  }

  // Helper method to print interests in a readable format
  static void printInterests(List<UserInterest> interests) {
    print('\n=== TOP REDDIT INTERESTS ===');
    for (var i = 0; i < interests.length; i++) {
      print('\n${i + 1}. ${interests[i].topic}');
      print(interests[i].toString());
    }
  }
} 