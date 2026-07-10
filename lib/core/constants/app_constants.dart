class AppConstants {
  // Change this to your machine's IP when testing on a physical device
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth
  static const String register    = '/auth/dj/registration/';
  static const String login       = '/auth/token/';
  static const String refreshToken= '/auth/token/refresh/';
  static const String logout      = '/auth/token/blacklist/';
  static const String me          = '/auth/me/';
  static const String becomeAuthor= '/auth/become-author/';
  static const String socialLogin = '/auth/social/';

  // Stories
  static const String stories     = '/stories/';
  static const String trending    = '/stories/trending/';
  static const String featured    = '/stories/featured/';
  static const String editorsPick = '/stories/editors-pick/';
  static const String bookmarks   = '/stories/bookmarks/';
  static const String genres      = '/stories/genres/';
  static const String tags        = '/stories/tags/';

  // Coins
  static const String coinPackages     = '/coins/packages/';
  static const String subscriptionPlans= '/coins/plans/';
  static const String coinBalance      = '/coins/balance/';
  static const String checkout         = '/coins/checkout/';
  static const String transactions     = '/coins/transactions/';

  // Notifications
  static const String notifications    = '/notifications/';
  static const String unreadCount      = '/notifications/unread/';
  static const String markAllRead      = '/notifications/mark-all-read/';

  // Storage keys
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey         = 'user_data';

  // App theme
  static const String appName = 'NoveluX';
}
