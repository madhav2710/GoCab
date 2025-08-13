import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import '../../services/feedback_service.dart';
import '../../services/auth_provider.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/feedback_tags_widget.dart';

class FeedbackHistoryScreen extends StatefulWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  State<FeedbackHistoryScreen> createState() => _FeedbackHistoryScreenState();
}

class _FeedbackHistoryScreenState extends State<FeedbackHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FeedbackService _feedbackService = FeedbackService();
  UserRating? _userRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRating();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRating() async {
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      final rating = await _feedbackService.getUserRating(user.uid);
      setState(() {
        _userRating = rating;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Feedback History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // User Rating Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[400]!, Colors.amber[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your Rating',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                RatingDisplayWidget(
                  rating: _userRating?.averageRating ?? 0.0,
                  totalRatings: _userRating?.totalRatings ?? 0,
                  size: 24,
                ),
                const SizedBox(height: 12),
                if (_userRating?.commonTags.isNotEmpty == true) ...[
                  Text(
                    'Common feedback:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FeedbackTagsDisplayWidget(
                    tags: _userRating!.commonTags,
                    size: 12,
                  ),
                ],
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Received'),
                Tab(text: 'Given'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Received Feedback Tab
                Container(
                  margin: const EdgeInsets.all(16),
                  child: _buildReceivedFeedbackTab(user.uid),
                ),

                // Given Feedback Tab
                Container(
                  margin: const EdgeInsets.all(16),
                  child: _buildGivenFeedbackTab(user.uid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedFeedbackTab(String userId) {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _feedbackService.getFeedbackReceived(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedbacks = snapshot.data ?? [];

        if (feedbacks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No feedback received yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete more rides to receive feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            return _buildFeedbackCard(feedback, false);
          },
        );
      },
    );
  }

  Widget _buildGivenFeedbackTab(String userId) {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _feedbackService.getUserFeedbackHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedbacks = snapshot.data ?? [];

        if (feedbacks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No feedback given yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rate your rides to help improve the community',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            return _buildFeedbackCard(feedback, true);
          },
        );
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback, bool isGiven) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  feedback.fromUserRole == 'driver' ? Icons.drive_eta : Icons.person,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGiven ? 'You rated ${feedback.toUserRole}' : '${feedback.fromUserRole} rated you',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      _formatDate(feedback.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              RatingDisplayWidget(
                rating: feedback.rating.toDouble(),
                size: 16,
                showText: false,
                showCount: false,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tags
          if (feedback.tags.isNotEmpty) ...[
            FeedbackTagsDisplayWidget(
              tags: feedback.tags,
              size: 10,
            ),
            const SizedBox(height: 12),
          ],

          // Feedback Text
          if (feedback.feedbackText != null && feedback.feedbackText!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback.feedbackText!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Anonymous indicator
          if (feedback.isAnonymous) ...[
            Row(
              children: [
                Icon(
                  Icons.visibility_off,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Anonymous feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
