// import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';
// import 'package:google_fonts/google_fonts.dart';

// // const Color kBrown = Color(0xFFB0FFC1);
// // const Color kDarkBrown =Color(0xFFB3C2FF);

// // // const Color kGrey = Color.fromARGB(255, 100, 105, 108);
// // // const Color kDarkGrey = Color(0xff878787);


// const Color color1 = Color(0xFFB0FFC1);
// const Color color2 = Color(0xFFB3C2FF);

// const Color purple = Color.fromARGB(255, 58, 71, 183);



// const Color kBrown = Color(0xff292526);
// const Color kDarkBrown = Color(0xff1b2028);

// const Color kGrey = Color.fromARGB(255, 100, 105, 108);
// const Color kDarkGrey = Color(0xff878787);

// const Color kLightGrey = Color(0xffededed);

// const Color kBorderColor = Color(0xffEAEAEA);

// const Color kWhite = Color(0xffffffff);


// //  Color(0xFFB0FFC1),
// //               Color(0xFFB3C2FF),

// const Color kBlack = Color(0xff111111);

// const Color kYellow = Color(0xffffd33c);

// const Color kBlue = Color(0xff347EFB);

// const double kBorderRadius = 12.0;

// const double kPaddingHorizontal = 24.0;

// final kInputBorder = OutlineInputBorder(
//   borderRadius: BorderRadius.circular(kBorderRadius),
//   borderSide: const BorderSide(
//     color: purple,
//   ),
// );

// final kEncodeSansBold = GoogleFonts.encodeSans(fontWeight: FontWeight.w700);

// final kEncodeSansSemiBold = GoogleFonts.encodeSans(fontWeight: FontWeight.w600);

// final kEncodeSansMedium = GoogleFonts.encodeSans(fontWeight: FontWeight.w500);

// final kEncodeSansRegular = GoogleFonts.encodeSans(fontWeight: FontWeight.w400);

// final kEncodeSansSmall = GoogleFonts.encodeSans(fontWeight: FontWeight.w200);



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Your existing colors
const Color color1 = Color(0xff878787);
const Color color2 = Color(0xFFB3C2FF);
const Color purple = Color(0xff332052);
const Color kBrown = Color(0xff292526);
const Color kDarkBrown = Color(0xff1b2028);
const Color kGrey = Color.fromARGB(255, 100, 105, 108);
const Color kDarkGrey = Color(0xff878787);
const Color kLightGrey = Color(0xffededed);
const Color kBorderColor = Color(0xffEAEAEA);
const Color kWhite = Color(0xffffffff);
const Color kBlack = Color(0xff111111);
const Color kYellow = Color(0xffffd33c);
const Color kBlue = Color(0xff347EFB);


const Color background = Color(0xff121212);
const Color normalTextColor = Color(0xfff1f1f1);
const Color accentBlue = Color(0xff4FC3F7);
const Color depperBlue = Color(0xFFC15F3C);
//Color(0xff0288D1);
const Color badge1 = Color(0xff4DB6AC);
const Color badge2 = Color(0xffFF8A65);
const Color badge3 = Color(0xffBA68C8);
const Color cyan = Color(0xff00BCD4);
const Color teal = Color(0xff009688);
const Color activeIcon = Color(0xff4FC3F7);
const Color subButton = Color(0xff03A9F4);

// Constants
const double kBorderRadius = 12.0;
const double kPaddingHorizontal = 24.0;

final kInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(kBorderRadius),
  borderSide: const BorderSide(
    color: purple,
  ),
);

// Font styles
final kEncodeSansBold = GoogleFonts.daysOne(fontWeight: FontWeight.w700);
final kEncodeSansSemiBold = GoogleFonts.daysOne(fontWeight: FontWeight.w600);
final kEncodeSansMedium = GoogleFonts.daysOne(fontWeight: FontWeight.w500);
final kEncodeSansRegular = GoogleFonts.daysOne(fontWeight: FontWeight.w400);
final kEncodeSansSmall = GoogleFonts.daysOne(fontWeight: FontWeight.w200);
final String kFontFamily = GoogleFonts.daysOne().fontFamily!;

// Custom Theme Class
class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xff332052),
    scaffoldBackgroundColor: const Color.fromARGB(255, 253, 201, 201),
    colorScheme: const ColorScheme.light(
      primary:  Color(0xff332052),
      secondary: kBlue,
      surface: kWhite,
      background: kWhite,
      error: Colors.red,
      onPrimary: kWhite,
      onSecondary: kWhite,
      onSurface: kBlack,
      onBackground: kBlack,
      onError: kWhite,
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor:const Color.fromARGB(251, 252, 251, 251),
      foregroundColor: kBlack,
      elevation: 0,
      titleTextStyle: kEncodeSansSemiBold.copyWith(
        color: kBlack,
        fontSize: 18,
      ),
      iconTheme: const IconThemeData(color: kBlack),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: kWhite,
      shadowColor: kGrey.withOpacity(0.1),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: const BorderSide(color: purple),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: const BorderSide(color: purple, width: 2),
      ),
      filled: true,
      fillColor: kWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kPaddingHorizontal,
        vertical: 16,
      ),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      headlineLarge: kEncodeSansBold.copyWith(
        color: kBlack,
        fontSize: 32,
      ),
      headlineMedium: kEncodeSansBold.copyWith(
        color: kBlack,
        fontSize: 28,
      ),
      headlineSmall: kEncodeSansSemiBold.copyWith(
        color: kBlack,
        fontSize: 24,
      ),
      titleLarge: kEncodeSansSemiBold.copyWith(
        color: kBlack,
        fontSize: 20,
      ),
      titleMedium: kEncodeSansMedium.copyWith(
        color: kBlack,
        fontSize: 16,
      ),
      bodyLarge: kEncodeSansRegular.copyWith(
        color: kBlack,
        fontSize: 16,
      ),
      bodyMedium: kEncodeSansRegular.copyWith(
        color: kGrey,
        fontSize: 14,
      ),
      bodySmall: kEncodeSansSmall.copyWith(
        color: kDarkGrey,
        fontSize: 12,
      ),
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: purple,
        foregroundColor: kWhite,
        textStyle: kEncodeSansMedium.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kPaddingHorizontal,
          vertical: 16,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: kBlack,
      size: 24,
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: color1,
    scaffoldBackgroundColor: const Color(0xFF0d0d0f),
    colorScheme: const ColorScheme.dark(
      primary: color1,
      secondary: color2,
      surface: kBlack,
      background: kBlack,
      error: Colors.redAccent,
      onPrimary: kBlack,
      onSecondary: kBlack,
      onSurface: kWhite,
      onBackground: kWhite,
      onError: kBlack,
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor:Color(0xff5f2e96).withValues(alpha: 0.02), //Colors.black.withValues(alpha: 0.5),
      foregroundColor: kWhite,
      elevation: 0,
      titleTextStyle: kEncodeSansSemiBold.copyWith(
        color: kWhite,
        fontSize: 18,
      ),
      iconTheme: const IconThemeData(color: kWhite),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: kBrown,
      shadowColor: kBlack.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: const BorderSide(color: color1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: const BorderSide(color: kDarkGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
        borderSide: const BorderSide(color: color1, width: 2),
      ),
      filled: true,
      fillColor: kBrown,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kPaddingHorizontal,
        vertical: 16,
      ),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      headlineLarge: kEncodeSansBold.copyWith(
        color: kWhite,
        fontSize: 32,
      ),
      headlineMedium: kEncodeSansBold.copyWith(
        color: kWhite,
        fontSize: 28,
      ),
      headlineSmall: kEncodeSansSemiBold.copyWith(
        color: kWhite,
        fontSize: 24,
      ),
      titleLarge: kEncodeSansSemiBold.copyWith(
        color: kWhite,
        fontSize: 20,
      ),
      titleMedium: kEncodeSansMedium.copyWith(
        color: kWhite,
        fontSize: 16,
      ),
      bodyLarge: kEncodeSansRegular.copyWith(
        color: kWhite,
        fontSize: 16,
      ),
      bodyMedium: kEncodeSansRegular.copyWith(
        color: kWhite,
        fontSize: 14,
      ),
      bodySmall: kEncodeSansSmall.copyWith(
        color: kWhite,
        fontSize: 12,
      ),
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: color1,
        foregroundColor: kBlack,
        textStyle: kEncodeSansMedium.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kPaddingHorizontal,
          vertical: 16,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: kWhite,
      size: 24,
    ),
  );
}

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// // class _MyAppState extends State<MyApp> {
// //   final ThemeProvider _themeProvider = ThemeProvider();
  
// //   @override
// //   void initState() {
// //     super.initState();
// //     _themeProvider.loadThemeMode();
// //     _themeProvider.addListener(() {
// //       setState(() {});
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Custom Theme Demo',
// //       theme: AppTheme.lightTheme,
// //       darkTheme: AppTheme.darkTheme,
// //       themeMode: _themeProvider.themeMode,
// //       home: HomeScreen(themeProvider: _themeProvider),
// //     );
// //   }
// // }

// // class HomeScreen extends StatefulWidget {
// //   final ThemeProvider themeProvider;
  
// //   const HomeScreen({Key? key, required this.themeProvider}) : super(key: key);

// //   @override
// //   _HomeScreenState createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen> {
// //   final TextEditingController _textController = TextEditingController();

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Custom Theme Demo'),
// //         actions: [
// //           IconButton(
// //             icon: Icon(
// //               widget.themeProvider.isDarkMode 
// //                 ? Icons.light_mode 
// //                 : Icons.dark_mode,
// //             ),
// //             onPressed: _showThemeDialog,
// //           ),
// //         ],
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(kPaddingHorizontal),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Header
// //             Text(
// //               'Welcome to Your App',
// //               style: Theme.of(context).textTheme.headlineLarge,
// //             ),
// //             const SizedBox(height: 8),
// //             Text(
// //               'This demonstrates your custom theme system',
// //               style: Theme.of(context).textTheme.bodyMedium,
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Sample Input Field
// //             TextField(
// //               controller: _textController,
// //               decoration: const InputDecoration(
// //                 labelText: 'Sample Input',
// //                 hintText: 'Type something...',
// //               ),
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Buttons
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: ElevatedButton(
// //                     onPressed: () {},
// //                     child: const Text('Primary Button'),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 16),
// //                 Expanded(
// //                   child: OutlinedButton(
// //                     onPressed: () {},
// //                     child: const Text('Secondary'),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Color Showcase
// //             Text(
// //               'Color Palette',
// //               style: Theme.of(context).textTheme.titleLarge,
// //             ),
// //             const SizedBox(height: 16),
// //             Wrap(
// //               spacing: 8,
// //               runSpacing: 8,
// //               children: [
// //                 _buildColorChip('Purple', purple),
// //                 _buildColorChip('Color 1', color1),
// //                 _buildColorChip('Color 2', color2),
// //                 _buildColorChip('Blue', kBlue),
// //                 _buildColorChip('Yellow', kYellow),
// //               ],
// //             ),
// //             const SizedBox(height: 24),
            
// //             // Sample Cards
// //             Text(
// //               'Sample Content',
// //               style: Theme.of(context).textTheme.titleLarge,
// //             ),
// //             const SizedBox(height: 16),
// //             ...List.generate(3, (index) => 
// //               Card(
// //                 margin: const EdgeInsets.only(bottom: 12),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(16),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         'Card Title ${index + 1}',
// //                         style: Theme.of(context).textTheme.titleMedium,
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         'This is sample content to show how your theme looks across different components.',
// //                         style: Theme.of(context).textTheme.bodyMedium,
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _showThemeDialog,
// //         child: const Icon(Icons.palette),
// //       ),
// //     );
// //   }
  
// //   Widget _buildColorChip(String name, Color color) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //       decoration: BoxDecoration(
// //         color: color,
// //         borderRadius: BorderRadius.circular(kBorderRadius / 2),
// //       ),
// //       child: Text(
// //         name,
// //         style: kEncodeSansSmall.copyWith(
// //           color: _getContrastColor(color),
// //           fontSize: 12,
// //         ),
// //       ),
// //     );
// //   }
  
// //   Color _getContrastColor(Color color) {
// //     return color.computeLuminance() > 0.5 ? kBlack : kWhite;
// //   }
  
// //   void _showThemeDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: const Text('Choose Theme'),
// //           content: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               RadioListTile<ThemeMode>(
// //                 title: const Text('Light'),
// //                 value: ThemeMode.light,
// //                 groupValue: widget.themeProvider.themeMode,
// //                 onChanged: (ThemeMode? value) {
// //                   if (value != null) {
// //                     widget.themeProvider.setThemeMode(value);
// //                     Navigator.pop(context);
// //                   }
// //                 },
// //               ),
// //               RadioListTile<ThemeMode>(
// //                 title: const Text('Dark'),
// //                 value: ThemeMode.dark,
// //                 groupValue: widget.themeProvider.themeMode,
// //                 onChanged: (ThemeMode? value) {
// //                   if (value != null) {
// //                     widget.themeProvider.setThemeMode(value);
// //                     Navigator.pop(context);
// //                   }
// //                 },
// //               ),
// //               RadioListTile<ThemeMode>(
// //                 title: const Text('System'),
// //                 value: ThemeMode.system,
// //                 groupValue: widget.themeProvider.themeMode,
// //                 onChanged: (ThemeMode? value) {
// //                   if (value != null) {
// //                     widget.themeProvider.setThemeMode(value);
// //                     Navigator.pop(context);
// //                   }
// //                 },
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
  
// //   @override
// //   void dispose() {
// //     _textController.dispose();
// //     super.dispose();
// //   }
// }