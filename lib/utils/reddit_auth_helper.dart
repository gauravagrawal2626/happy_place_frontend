import 'dart:convert';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'reddit_interest_analyzer.dart';

class RedditAuthHelper {
  static const String clientId = 'J1uvl8VmZh2vJGf4aYQa_w';
  static const String redirectUri = 'com.happyplace://oauth2redirect';
  static const String scope = 'identity read history';

  static Future<String?> getAccessToken() async {
    final url = Uri.https('www.reddit.com', '/api/v1/authorize', {
      'client_id': clientId,
      'response_type': 'token',
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
      'redirect_uri': redirectUri,
      'duration': 'temporary',
      'scope': scope,
    });

    print('Starting Reddit OAuth flow with URL: ${url.toString()}');

    try {
      final result = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'com.happyplace',
      );

      print('OAuth result: $result');

      if (result.isEmpty) {
        print('Empty result from OAuth flow');
        return null;
      }

      final uri = Uri.parse(result);
      final fragment = uri.fragment;
      print('URI fragment: $fragment');

      if (fragment.isEmpty) {
        print('Empty fragment in URI');
        return null;
      }

      final accessToken = fragment
          .split('&')
          .firstWhere(
            (param) => param.startsWith('access_token='),
            orElse: () => '',
          )
          .split('=')
          .last;

      print('Extracted access token: ${accessToken.isNotEmpty ? 'Token received' : 'No token found'}');
      return accessToken.isEmpty ? null : accessToken;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        print('User canceled the authentication');
        return null;
      }
      print('Error getting access token: $e');
      return null;
    } catch (e) {
      print('Unexpected error during authentication: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserComments(String accessToken, String username, {int limit = 10}) async {
    try {
      print('Fetching comments for user: $username');
      final response = await http.get(
        Uri.https('oauth.reddit.com', '/user/$username/comments.json', {
          'limit': limit.toString(),
          'sort': 'new',
          'raw_json': '1',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'HappyPlace/1.0.0',
        },
      );

      print('Comments response status: ${response.statusCode}');
      print('Comments response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] == null || data['data']['children'] == null) {
          print('No comments found in response');
          return [];
        }

        final comments = (data['data']['children'] as List)
            .map((comment) {
              final commentData = comment['data'] as Map<String, dynamic>;
              // Convert numeric values to int
              if (commentData['created_utc'] != null) {
                commentData['created_utc'] = (commentData['created_utc'] as num).toInt();
              }
              if (commentData['score'] != null) {
                commentData['score'] = (commentData['score'] as num).toInt();
              }
              return commentData;
            })
            .toList();

        print('\n=== RECENT COMMENTS ===');
        for (var comment in comments) {
          print('\nComment in r/${comment['subreddit']}:');
          print('- Body: ${comment['body']}');
          print('- Score: ${comment['score']}');
          print('- Created: ${DateTime.fromMillisecondsSinceEpoch(comment['created_utc'] * 1000)}');
          print('- Link: https://reddit.com${comment['permalink']}');
        }

        return comments;
      }
      print('Error getting comments: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(String accessToken, String username, {int limit = 10}) async {
    try {
      print('Fetching posts for user: $username');
      final response = await http.get(
        Uri.https('oauth.reddit.com', '/user/$username/submitted.json', {
          'limit': limit.toString(),
          'sort': 'new',
          'raw_json': '1',
        }),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'HappyPlace/1.0.0',
        },
      );

      print('Posts response status: ${response.statusCode}');
      print('Posts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] == null || data['data']['children'] == null) {
          print('No posts found in response');
          return [];
        }

        final posts = (data['data']['children'] as List)
            .map((post) {
              final postData = post['data'] as Map<String, dynamic>;
              // Convert numeric values to int
              if (postData['created_utc'] != null) {
                postData['created_utc'] = (postData['created_utc'] as num).toInt();
              }
              if (postData['score'] != null) {
                postData['score'] = (postData['score'] as num).toInt();
              }
              return postData;
            })
            .toList();

        print('\n=== RECENT POSTS ===');
        for (var post in posts) {
          print('\nPost in r/${post['subreddit']}:');
          print('- Title: ${post['title']}');
          print('- Score: ${post['score']}');
          print('- Created: ${DateTime.fromMillisecondsSinceEpoch(post['created_utc'] * 1000)}');
          print('- Link: https://reddit.com${post['permalink']}');
          if (post['selftext'] != null && post['selftext'].isNotEmpty) {
            print('- Content: ${post['selftext']}');
          }
        }

        return posts;
      }
      print('Error getting posts: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo(String accessToken) async {
    print('Getting user info with token: ${accessToken.substring(0, 5)}...');
    try {
      // Get basic user info
      final userResponse = await http.get(
        Uri.https('oauth.reddit.com', '/api/v1/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'HappyPlace/1.0.0',
        },
      );

      print('User info response status: ${userResponse.statusCode}');
      print('User info response body: ${userResponse.body}');

      if (userResponse.statusCode == 200) {
        final userInfo = json.decode(userResponse.body);
        // Convert numeric values to int
        if (userInfo['created_utc'] != null) {
          userInfo['created_utc'] = (userInfo['created_utc'] as num).toInt();
        }
        if (userInfo['total_karma'] != null) {
          userInfo['total_karma'] = (userInfo['total_karma'] as num).toInt();
        }
        
        final username = userInfo['name'];
        
        // Get user's karma breakdown
        final karmaResponse = await http.get(
          Uri.https('oauth.reddit.com', '/api/v1/me/karma'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': 'HappyPlace/1.0.0',
          },
        );

        if (karmaResponse.statusCode == 200) {
          final karmaInfo = json.decode(karmaResponse.body);
          if (karmaInfo['data'] != null) {
            karmaInfo['data'] = (karmaInfo['data'] as List).map((karma) {
              final karmaData = karma as Map<String, dynamic>;
              if (karmaData['link_karma'] != null) {
                karmaData['link_karma'] = (karmaData['link_karma'] as num).toInt();
              }
              if (karmaData['comment_karma'] != null) {
                karmaData['comment_karma'] = (karmaData['comment_karma'] as num).toInt();
              }
              return karmaData;
            }).toList();
          }
          userInfo['karma_breakdown'] = karmaInfo;
        }

        // Get user's preferences
        final prefsResponse = await http.get(
          Uri.https('oauth.reddit.com', '/api/v1/me/prefs'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': 'HappyPlace/1.0.0',
          },
        );

        if (prefsResponse.statusCode == 200) {
          final prefsInfo = json.decode(prefsResponse.body);
          userInfo['preferences'] = prefsInfo;
        }

        // Get user's trophies
        final trophiesResponse = await http.get(
          Uri.https('oauth.reddit.com', '/api/v1/me/trophies'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': 'HappyPlace/1.0.0',
          },
        );

        if (trophiesResponse.statusCode == 200) {
          final trophiesInfo = json.decode(trophiesResponse.body);
          userInfo['trophies'] = trophiesInfo;

          // Get recent comments
          final comments = await getUserComments(accessToken, username);
          userInfo['recent_comments'] = comments;

          // Get recent posts
          final posts = await getUserPosts(accessToken, username);
          userInfo['recent_posts'] = posts;

          // Analyze user interests
          final trophies = (trophiesInfo['data']['trophies'] as List)
              .map((t) => t['data'] as Map<String, dynamic>)
              .toList();
          
          final topInterests = RedditInterestAnalyzer.extractTopInterests(
            posts: posts,
            comments: comments,
            trophies: trophies,
          );
          
          userInfo['top_interests'] = topInterests;
          RedditInterestAnalyzer.printInterests(topInterests);
        }

        // Print all available information
        print('\n=== REDDIT USER INFORMATION ===');
        print('Basic Info:');
        print('- Username: ${userInfo['name']}');
        print('- ID: ${userInfo['id']}');
        print('- Created: ${DateTime.fromMillisecondsSinceEpoch(userInfo['created_utc'] * 1000)}');
        print('- Has verified email: ${userInfo['has_verified_email']}');
        print('- Is gold: ${userInfo['is_gold']}');
        print('- Is mod: ${userInfo['is_mod']}');
        print('- Icon URL: ${userInfo['icon_img']}');
        print('- Banner URL: ${userInfo['subreddit']?['banner_img']}');
        print('- Description: ${userInfo['subreddit']?['public_description']}');
        
        if (userInfo['karma_breakdown'] != null) {
          print('\nKarma Breakdown:');
          for (var karma in userInfo['karma_breakdown']['data']) {
            print('- ${karma['sr']}: ${karma['link_karma']} link karma, ${karma['comment_karma']} comment karma');
          }
        }

        if (userInfo['preferences'] != null) {
          print('\nPreferences:');
          print('- Default comment sort: ${userInfo['preferences']['default_comment_sort']}');
          print('- Show trending: ${userInfo['preferences']['show_trending']}');
          print('- Show link flair: ${userInfo['preferences']['show_link_flair']}');
          print('- Show location based recommendations: ${userInfo['preferences']['show_location_based_recommendations']}');
        }

        if (userInfo['trophies'] != null) {
          print('\nTrophies:');
          for (var trophy in userInfo['trophies']['data']['trophies']) {
            print('- ${trophy['name']}: ${trophy['description']}');
          }
        }

        return userInfo;
      }
      print('Error getting user info: ${userResponse.statusCode} - ${userResponse.body}');
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
} 