import 'package:get/get.dart';
import 'package:novelux/screen/auth/auth_controller.dart';
import 'package:novelux/screen/auth/auth_screens.dart';
import 'package:novelux/screen/author/author_dashboard_screen.dart';
import 'package:novelux/screen/author/preferences_screen.dart';
import 'package:novelux/screen/book_preview/story_detail_screen.dart';
import 'package:novelux/screen/coins/coin_store_screen.dart';
import 'package:novelux/screen/explore/bindings/explore_bindings.dart';
import 'package:novelux/screen/explore/explore_screen.dart';
import 'package:novelux/screen/explore/search.dart';
import 'package:novelux/screen/genres/bindings/genres_bindings.dart';
import 'package:novelux/screen/genres/genres_screen.dart';
import 'package:novelux/screen/library/bindings/library_bindings.dart';
import 'package:novelux/screen/library/library_screen.dart';
import 'package:novelux/screen/main_screen/main_screen.dart';
import 'package:novelux/screen/me/bindings/me_bindings.dart';
import 'package:novelux/screen/me/me_screen.dart';
import 'package:novelux/screen/notification_screen/bindings/notifcation_binding.dart';
import 'package:novelux/screen/notification_screen/notification_screen.dart';
import 'package:novelux/screen/onboarding/onboarding.dart';
import 'package:novelux/screen/splash_screen/splash_screen.dart';


class AppRoutes {
  static const splashScreen        = '/splash_screen';
  static const onboardingScreen    = '/onboarding_screen';
  static const loginScreen         = '/login_screen';
  static const registerScreen      = '/register_screen';
  static const mainScreen          = '/main_screen';
  static const meScreen            = '/me_screen';
  static const genresScreen        = '/genres_screen';
  static const exploreScreen       = '/explore_screen';
  static const libraryScreen       = '/library_screen';
  static const notificationScreen  = '/notification_screen';
  static const storyDetailScreen   = '/story_detail';
  static const coinStoreScreen     = '/coin_store';
  static const authorDashboard     = '/author_dashboard';
  static const preferencesScreen   = '/preferences_screen';
  static const searchScreen        = '/search_screen';

  static List<GetPage> pages = [
    GetPage(name: splashScreen,       page: () => const SplashScreen()),
    GetPage(name: onboardingScreen,   page: () => const Onboarding()),
    GetPage(
      name: loginScreen,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() => Get.put(AuthController())),
    ),
    GetPage(name: registerScreen,     page: () => const RegisterScreen()),
    GetPage(name: mainScreen,         page: () => const MainScreen()),
    GetPage(name: meScreen,           page: () => const MeScreen(), bindings: [MeBindings()]),
    GetPage(name: genresScreen,       page: () => const GenresScreen(), bindings: [GenresBindings()]),
    GetPage(name: libraryScreen,      page: () => const LibraryScreen(), bindings: [LibraryBindings()]),
    GetPage(name: exploreScreen,      page: () => const ExploreScreen(), bindings: [ExploreBindings()]),
    GetPage(
      name: notificationScreen,
      page: () => const NotificationScreen(),
      bindings: [NotifcationBinding()],
    ),
    GetPage(
      name: storyDetailScreen,
      page: () => StoryDetailScreen(slug: Get.arguments as String),
    ),
    GetPage(name: coinStoreScreen,    page: () => const CoinStoreScreen()),
    GetPage(name: preferencesScreen,  page: () => const PreferencesScreen()),
    GetPage(name: searchScreen,        page: () => const SearchScreen()),
    GetPage(name: authorDashboard,    page: () => const AuthorDashboardScreen()),
  ];
}