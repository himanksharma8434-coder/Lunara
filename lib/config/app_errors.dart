class AppErrors {
  // 1. Connection Issues
  static const String connectionTitle = "Connection Issue";
  static const String connectionMessage = "We're having trouble connecting to the internet right now. Please check your Wi-Fi or cellular connection and try again.";

  // 2. System / Server Outage
  static const String serverTitle = "System Error";
  static const String serverMessage = "Oops! Something went wrong on our end. We're working hard to get things back to normal. Please try again in a few minutes.";

  // 3. Data Loading Error
  static const String dataLoadingTitle = "Data Unavailable";
  static const String dataLoadingMessage = "We couldn't load your information right now. Give it another try, or pull down on the screen to refresh the page.";

  // 4. Data Saving Error
  static const String dataSavingTitle = "Couldn't Save";
  static const String dataSavingMessage = "We hit a snag and couldn't save your entry this time. Please make sure you're connected to the internet and try saving again.";

  // 5. Session Expired
  static const String sessionExpiredTitle = "Session Expired";
  static const String sessionExpiredMessage = "For your security, it looks like your session has timed out. Please log back in to pick up right where you left off.";

  // 6. High Traffic / Rate Limiting
  static const String rateLimitTitle = "High Traffic";
  static const String rateLimitMessage = "Our systems are getting a lot of love right now and need a breather! Please wait just a moment before trying again.";

  // 7. Invalid Credentials
  static const String invalidAuthTitle = "Login Failed";
  static const String invalidAuthMessage = "We couldn't recognize those account details. Please double-check your email and password, or use the reset password link if you're stuck.";

  // 8. Feature Unavailable
  static const String maintenanceTitle = "Feature Unavailable";
  static const String maintenanceMessage = "This feature is currently taking a quick break for improvements. We'll have it back up and running shortly. Thanks for your patience!";

  // 9. Generic / Unexpected Error
  static const String genericTitle = "Oops!";
  static const String genericMessage = "Hmm, that didn't go as expected. We're sorry for the hiccup! Please try closing the app and opening it again, or try again later.";
}
