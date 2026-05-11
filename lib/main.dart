import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  runApp(MyApp());
}

// 1. PRIMERO: Clase MyApp
class MyApp extends StatelessWidget {
  // Color corporativo principal
  static const Color primaryColor = Color(0xFF0143A4);
  static const Color secondaryColor = Color(0xFF0056D6);
  static const Color accentColor = Color(0xFFE8F0FE);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encuestas App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: Colors.white,
          background: Colors.grey[50]!,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
      cardTheme: CardThemeData(  // ✅ Correcto
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
        
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

// 2. AQUÍ VA: Widget CorporateLogo (logo basado en iconos)
class CorporateLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  
  const CorporateLogo({
    Key? key,
    this.size = 40,
    this.showText = true,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? MyApp.primaryColor;
    
    return showText 
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoIcon(logoColor),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Encuestas',
                  style: TextStyle(
                    color: logoColor,
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'CORPORATIVAS',
                  style: TextStyle(
                    color: logoColor.withOpacity(0.7),
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        )
      : _buildLogoIcon(logoColor);
  }

  Widget _buildLogoIcon(Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.assignment_turned_in,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// 3. AQUÍ VA: Widget ImageLogo (logo basado en imagen)
class ImageLogo extends StatelessWidget {
  final double size;
  final bool showText;
  
  const ImageLogo({Key? key, this.size = 40, this.showText = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return showText 
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: size, height: size),
            SizedBox(width: 12),
            Text(
              'Encuestas',
              style: TextStyle(
                color: MyApp.primaryColor,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )
      : Image.asset('assets/images/logo.png', width: size, height: size);
  }
}

// 4. AQUÍ VA: Widget LogoAppBar
class LogoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  
  const LogoAppBar({
    Key? key,
    this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null 
        ? Text(title!) 
        : CorporateLogo(showText: false, color: Colors.white, size: 35),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MyApp.primaryColor,
              MyApp.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}