//@dart=2.12
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get_it/get_it.dart';
import 'package:little_light/services/user_settings/little_light_persistent_page.dart';
import 'package:little_light/utils/platform_capabilities.dart';

setupAnalyticsService() async {
  GetIt.I.registerSingleton<AnalyticsService>(AnalyticsService._internal());
}

class AnalyticsService {
  FirebaseAnalytics _analytics = FirebaseAnalytics();
  
  AnalyticsService._internal();

  registerPageOpen(LittleLightPersistentPage page) {
    if (PlatformCapabilities.firebaseAnalyticsAvailable) {
      _analytics.setCurrentScreen(
          screenName: page.name, screenClassOverride: page.name);
    }
  }
}
