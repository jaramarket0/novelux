import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/utils.dart';
import 'package:novelux/config/app_style.dart';
import 'package:novelux/config/local_storage.dart';
import 'package:novelux/config/routes.dart';


// GetX Theme Controller
class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();
  
  final _isDarkMode = false.obs;
  final _themeMode = ThemeMode.system.obs;
  
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _themeMode.value;
  
  @override
  void onInit() {
    super.onInit();
    loadThemeMode();
  }
  
  void toggleTheme() {
    if (_themeMode.value == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
  
  void setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    _updateIsDarkMode();
    
    // Save to local storage using your existing DataBase class
    DataBase dataBase = Get.find<DataBase>();
    await dataBase.saveThemeMode(mode.toString());
    
    // Update GetX theme
    Get.changeThemeMode(mode);
  }
  
  void loadThemeMode() async {
    try {
      DataBase dataBase = Get.find<DataBase>();
      String? savedTheme = await dataBase.getThemeMode();
      
      if (savedTheme != null && savedTheme.isNotEmpty) {
        switch (savedTheme) {
          case 'ThemeMode.light':
            _themeMode.value = ThemeMode.light;
            break;
          case 'ThemeMode.dark':
            _themeMode.value = ThemeMode.dark;
            break;
          case 'ThemeMode.system':
          default:
            _themeMode.value = ThemeMode.system;
            break;
        }
      }
      _updateIsDarkMode();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }
  
  void _updateIsDarkMode() {
    if (_themeMode.value == ThemeMode.system) {
      _isDarkMode.value = Get.isPlatformDarkMode;
    } else {
      _isDarkMode.value = _themeMode.value == ThemeMode.dark;
    }
  }
}

// Custom Theme Switch Widget for GetX
class ThemeSwitch extends StatelessWidget {
  final double? width;
  final double? height;
  
  const ThemeSwitch({
    Key? key,
    this.width = 60,
    this.height = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<ThemeController>(
      builder: (controller) {
        return GestureDetector(
          onTap: () => controller.toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height! / 2),
              color: controller.isDarkMode ? color1 : purple,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background icons
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.wb_sunny,
                      size: 16,
                      color: controller.isDarkMode 
                        ? kGrey.withOpacity(0.5)
                        : kWhite,
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.nightlight_round,
                      size: 16,
                      color: controller.isDarkMode 
                        ? kBlack
                        : kWhite.withOpacity(0.5),
                    ),
                  ),
                ),
                
                // Sliding circle
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: controller.isDarkMode ? width! - height! + 2 : 2,
                  top: 2,
                  child: Container(
                    width: height! - 4,
                    height: height! - 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kWhite,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      controller.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                      size: 14,
                      color: controller.isDarkMode ? color1 : purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Simple Material Switch for GetX
class SimpleThemeSwitch extends StatelessWidget {
  const SimpleThemeSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<ThemeController>(
      builder: (controller) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny,
              size: 20,
              color: controller.isDarkMode ? kGrey : purple,
            ),
            const SizedBox(width: 8),
            Switch(
              value: controller.isDarkMode,
              onChanged: (value) => controller.toggleTheme(),
              activeColor: color1,
              activeTrackColor: color1.withOpacity(0.3),
              inactiveThumbColor: purple,
              inactiveTrackColor: purple.withOpacity(0.3),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.nightlight_round,
              size: 20,
              color: controller.isDarkMode ? color1 : kGrey,
            ),
          ],
        );
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Initialize your existing services
  DataBase dataBase = Get.put(DataBase());
  
  // Initialize theme controller
  Get.put(ThemeController());
  
  var token = await dataBase.getToken();
  String initialRoute = token.isNotEmpty ? '/main_screen' : '/splash_screen';
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<ThemeController>(
      builder: (themeController) {
        return  GetMaterialApp(
            title: 'NoveluX',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            initialRoute: AppRoutes.splashScreen,
            getPages: AppRoutes.pages,
          // ),
        );
      },
    );
  }
}

// Extension for your DataBase class - add these methods to your existing DataBase class
extension ThemeStorage on DataBase {
  Future<void> saveThemeMode(String themeMode) async {
    // Use your existing storage method
    // Example: await storage.write(key: 'theme_mode', value: themeMode);
    // Or however you're currently saving data
  }
  
  Future<String?> getThemeMode() async {
    // Use your existing storage method
    // Example: return await storage.read(key: 'theme_mode');
    // Or however you're currently reading data
    return null; // Replace with your actual implementation
  }
}

// Example usage in any screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          // Add theme switch to app bar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ThemeSwitch(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Settings tile with switch
            GetX<ThemeController>(
              builder: (controller) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    controller.isDarkMode ? 'Enabled' : 'Disabled',
                  ),
                  value: controller.isDarkMode,
                  onChanged: (value) => controller.toggleTheme(),
                  activeColor: controller.isDarkMode ? color1 : purple,
                  secondary: Icon(
                    controller.isDarkMode 
                      ? Icons.nightlight_round 
                      : Icons.wb_sunny,
                    color: controller.isDarkMode ? color1 : purple,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Simple switch example
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Theme Toggle'),
                    SimpleThemeSwitch(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}