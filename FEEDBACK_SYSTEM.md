# GoCab Ride Feedback System

## Overview

The GoCab app now includes a comprehensive ride feedback system that allows both riders and drivers to rate each other after ride completion. The system provides detailed feedback collection, rating calculations, and feedback history management.

## Features

### 1. Post-Ride Rating
- **Automatic Prompt**: Rating screen appears after ride completion
- **Star Rating**: 1-5 star rating system with visual feedback
- **Rating Descriptions**: Contextual descriptions for each rating level
- **Anonymous Option**: Users can submit feedback anonymously

### 2. Feedback Tags
- **Driver Tags**: Safe Driving, Clean Vehicle, Punctual, Friendly, Professional, etc.
- **Rider Tags**: Punctual, Friendly, Respectful, Clean, Good Communication, etc.
- **Multi-Selection**: Users can select up to 5 tags
- **Visual Selection**: Interactive tag selection with checkmarks

### 3. Text Feedback
- **Optional Comments**: Users can provide detailed text feedback
- **Character Limit**: 500 character limit for comments
- **Rich Text Support**: Proper formatting and display

### 4. User Rating System
- **Average Rating**: Calculated from all received feedback
- **Rating Distribution**: Breakdown of 1-5 star ratings
- **Common Tags**: Most frequently mentioned positive attributes
- **Real-time Updates**: Ratings update automatically

### 5. Feedback History
- **Given Feedback**: History of feedback provided by user
- **Received Feedback**: History of feedback received by user
- **Detailed View**: Complete feedback information with timestamps
- **Anonymous Indicators**: Clear indication of anonymous feedback

## Technical Implementation

### Models

#### FeedbackModel
```dart
class FeedbackModel {
  final String id;
  final String rideId;
  final String fromUserId;
  final String toUserId;
  final String fromUserRole; // 'rider' or 'driver'
  final String toUserRole; // 'rider' or 'driver'
  final int rating; // 1-5 stars
  final String? feedbackText;
  final List<String> tags;
  final DateTime createdAt;
  final bool isAnonymous;
}
```

#### UserRating
```dart
class UserRating {
  final String userId;
  final double averageRating;
  final int totalRatings;
  final Map<String, int> ratingDistribution;
  final List<String> commonTags;
  final DateTime lastUpdated;
}
```

### Services

#### FeedbackService
The core service that handles all feedback-related operations:

- **Feedback Submission**: Submit new feedback with validation
- **Rating Calculation**: Calculate and update user ratings
- **Feedback Retrieval**: Get feedback history and statistics
- **Ride Tracking**: Track which rides need feedback
- **User Rating Management**: Manage user rating documents

#### Key Methods:
```dart
// Submit feedback
Future<FeedbackModel?> submitFeedback({...})

// Get feedback history
Stream<List<FeedbackModel>> getUserFeedbackHistory(String userId)
Stream<List<FeedbackModel>> getFeedbackReceived(String userId)

// Get user rating
Future<UserRating?> getUserRating(String userId)
Stream<UserRating?> getUserRatingStream(String userId)

// Check if ride was rated
Future<bool> hasUserRatedRide(String rideId, String userId)
```

### UI Components

#### RatingWidget
Interactive star rating widget with animations and descriptions.

#### RatingDisplayWidget
Display widget for showing ratings with stars and text.

#### FeedbackTagsWidget
Tag selection widget with different tag sets for drivers and riders.

#### FeedbackTagsDisplayWidget
Display widget for showing selected tags.

#### FeedbackScreen
Main feedback collection screen with all rating components.

#### FeedbackHistoryScreen
Comprehensive feedback history with tabs for given and received feedback.

## Setup Instructions

### 1. Firebase Collections
The system uses the following Firestore collections:
- `feedback`: Individual feedback records
- `user_ratings`: Calculated user rating summaries
- `rides`: Updated with rating tracking

### 2. Integration Points
- **Ride Completion**: Automatic feedback prompt in ride tracking
- **Home Screen**: Feedback history access button
- **User Profiles**: Display user ratings and feedback

## Usage Examples

### 1. Submitting Feedback
```dart
final feedback = await feedbackService.submitFeedback(
  rideId: ride.id,
  fromUserId: currentUser.uid,
  toUserId: otherUser.uid,
  fromUserRole: 'rider',
  toUserRole: 'driver',
  rating: 5,
  feedbackText: 'Great experience!',
  tags: ['Safe Driving', 'Friendly'],
  isAnonymous: false,
);
```

### 2. Getting User Rating
```dart
final userRating = await feedbackService.getUserRating(userId);
if (userRating != null) {
  print('Average Rating: ${userRating.averageRating}');
  print('Total Ratings: ${userRating.totalRatings}');
}
```

### 3. Using Rating Widget
```dart
RatingWidget(
  initialRating: 0,
  onRatingChanged: (rating) {
    setState(() {
      selectedRating = rating;
    });
  },
  size: 48,
)
```

### 4. Using Feedback Tags Widget
```dart
FeedbackTagsWidget(
  selectedTags: selectedTags,
  onTagsChanged: (tags) {
    setState(() {
      selectedTags = tags;
    });
  },
  isForDriver: true, // true for rating drivers, false for riders
)
```

## Feedback Flow

### 1. Ride Completion Flow
1. Ride status changes to "completed"
2. System checks if user has already rated the ride
3. If not rated, shows feedback prompt dialog
4. User can choose to rate now or skip
5. If user chooses to rate, navigates to feedback screen

### 2. Feedback Collection Flow
1. User selects star rating (1-5)
2. User selects relevant tags (optional, max 5)
3. User provides text feedback (optional)
4. User chooses anonymous option (optional)
5. Feedback is submitted to Firestore
6. User rating is recalculated and updated
7. Ride is marked as rated

### 3. Rating Calculation Flow
1. All feedback for a user is retrieved
2. Average rating is calculated
3. Rating distribution is computed (1-5 stars)
4. Common tags are identified (mentioned 2+ times)
5. User rating document is updated
6. Real-time updates are sent to UI

## User Experience Features

### 1. Visual Feedback
- **Animated Stars**: Smooth animations when selecting ratings
- **Color Coding**: Different colors for different rating levels
- **Progress Indicators**: Loading states during submission
- **Success Messages**: Confirmation after successful submission

### 2. Accessibility
- **Screen Reader Support**: Proper labels and descriptions
- **Touch Targets**: Adequate size for mobile interaction
- **Color Contrast**: High contrast for readability
- **Keyboard Navigation**: Full keyboard support

### 3. User Guidance
- **Clear Instructions**: Step-by-step guidance
- **Contextual Help**: Help text for each section
- **Validation Messages**: Clear error messages
- **Progress Indicators**: Show completion status

## Security Features

### 1. Data Validation
- Rating validation (1-5 stars)
- Tag limit enforcement (max 5 tags)
- Text length validation (max 500 characters)
- User authentication required

### 2. Privacy Protection
- Anonymous feedback option
- User consent for feedback collection
- Data retention policies
- Secure data transmission

### 3. Anti-Abuse Measures
- One feedback per ride per user
- Rate limiting for feedback submission
- Content moderation capabilities
- Report inappropriate feedback

## Analytics and Insights

### 1. Rating Analytics
- Average ratings by user
- Rating trends over time
- Rating distribution analysis
- Performance comparisons

### 2. Tag Analytics
- Most common positive tags
- Tag correlation analysis
- Improvement areas identification
- Success metrics tracking

### 3. User Behavior
- Feedback completion rates
- Anonymous vs. named feedback
- Text feedback analysis
- User engagement metrics

## Testing

Run the feedback system tests:
```bash
flutter test test/feedback_test.dart
```

## Future Enhancements

### Planned Features
1. **Feedback Templates**: Pre-defined feedback templates
2. **Photo Feedback**: Allow photo attachments
3. **Voice Feedback**: Voice-to-text feedback option
4. **Feedback Rewards**: Incentives for providing feedback
5. **Advanced Analytics**: Machine learning insights

### Technical Improvements
1. **Offline Support**: Cache feedback for offline submission
2. **Push Notifications**: Remind users to rate rides
3. **Feedback Scheduling**: Delayed feedback prompts
4. **Multi-language Support**: Internationalization
5. **Advanced Filtering**: Filter feedback by various criteria

## Troubleshooting

### Common Issues

1. **Feedback Not Submitting**
   - Check internet connectivity
   - Verify user authentication
   - Ensure all required fields are filled

2. **Rating Not Updating**
   - Check Firestore connection
   - Verify rating calculation logic
   - Refresh the app

3. **Feedback Prompt Not Showing**
   - Check ride completion status
   - Verify user hasn't already rated
   - Check feedback service initialization

### Debug Mode
Enable debug logging by setting:
```dart
static const bool _debugMode = true;
```

## Support

For technical support or questions about the feedback system:
1. Check the error logs in the console
2. Verify Firebase configuration
3. Test with different user roles
4. Review feedback service documentation

## License

This feedback system is part of the GoCab application and follows the same licensing terms.
