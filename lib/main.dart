import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/link_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LinkProvider(),
      child: const LinkSaverApp(),
    ),
  );
}

class LinkSaverApp extends StatefulWidget {
  const LinkSaverApp({super.key});

  @override
  State<LinkSaverApp> createState() => _LinkSaverAppState();
}

class _LinkSaverAppState extends State<LinkSaverApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      home: _ThemeToggleWrapper(
        themeMode: _themeMode,
        onToggle: _toggleTheme,
        child: const HomeScreen(),
      ),
    );
  }
}

class _ThemeToggleWrapper extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggle;

  const _ThemeToggleWrapper({
    required this.themeMode,
    required this.onToggle,
    required super.child,
  });

  // ignore: unused_element
  static _ThemeToggleWrapper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeToggleWrapper>();
  }

  @override
  bool updateShouldNotify(_ThemeToggleWrapper old) =>
      themeMode != old.themeMode;
}