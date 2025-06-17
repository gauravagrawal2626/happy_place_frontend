import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/bloc/linkedin_auth_bloc.dart';
import '../../auth/bloc/linkedin_auth_event.dart';
import '../../auth/bloc/linkedin_auth_state.dart';
import '../../../utils/reddit_auth_helper.dart';
import '../../../utils/reddit_interest_analyzer.dart';
import '../widgets/cv_uploader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _redditUserInfo;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _connectToReddit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await RedditAuthHelper.getAccessToken();
      if (accessToken == null) {
        setState(() {
          _errorMessage = 'Failed to connect to Reddit. Please try again.';
        });
        return;
      }

      final userInfo = await RedditAuthHelper.getUserInfo(accessToken);
      if (userInfo == null) {
        setState(() {
          _errorMessage = 'Failed to get Reddit user info. Please try again.';
        });
        return;
      }

      setState(() {
        _redditUserInfo = userInfo;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _disconnectReddit() {
    setState(() {
      _redditUserInfo = null;
      _errorMessage = null;
    });
  }

  Widget _buildInterestsSection() {
    if (_redditUserInfo == null || _redditUserInfo!['top_interests'] == null) {
      return const SizedBox.shrink();
    }

    final interests = _redditUserInfo!['top_interests'] as List<UserInterest>;
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Your Top Interests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...interests.map((interest) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'r/${interest.topic}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Score: ${interest.engagementScore.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${interest.postCount} posts • ${interest.commentCount} comments',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (interest.trophies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: interest.trophies.map((trophy) {
                      return Chip(
                        label: Text(trophy),
                        backgroundColor: Colors.amber.shade100,
                        labelStyle: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<LinkedInAuthBloc>().add(LinkedInLogoutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: BlocBuilder<LinkedInAuthBloc, LinkedInAuthState>(
        builder: (context, state) {
          if (state is LinkedInAuthSuccess) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.user.firstName} ${state.user.lastName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (state.user.profileUrl != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse(state.user.profileUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Text(
                        'LinkedIn Profile',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Reddit Connection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_errorMessage != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _connectToReddit,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_redditUserInfo != null)
                    Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (_redditUserInfo!['icon_img'] != null)
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          _redditUserInfo!['icon_img'],
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'u/${_redditUserInfo!['name']}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Karma: ${_redditUserInfo!['total_karma']}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _disconnectReddit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Disconnect Reddit'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildInterestsSection(),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: _connectToReddit,
                      child: const Text('Connect to Reddit'),
                    ),
                  const SizedBox(height: 32),
                  const CVUploader(),
                ],
              ),
            );
          }
          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }
} 