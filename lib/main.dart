import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/api_provider.dart';
import 'services/log_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/config_service.dart';
import 'widgets/config_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = await ConfigService.create();
  if (!configService.isConfigured) {
    runApp(ConfigApp(configService: configService));
  } else {
    runApp(MyApp(configService: configService));
  }
}

class ConfigApp extends StatelessWidget {
  final ConfigService configService;

  const ConfigApp({super.key, required this.configService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primaryColor: Colors.cyanAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.pinkAccent,
        ),
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E21),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: Center(
            child: ConfigDialog(
              configService: configService,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final ConfigService configService;

  const MyApp({super.key, required this.configService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: configService),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        ChangeNotifierProvider(create: (_) => LogService()),
      ],
      child: MaterialApp(
        title: 'AI API Assistant',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0E21),
          primaryColor: Colors.cyanAccent,
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            secondary: Colors.pinkAccent,
            surface: Color(0xFF1D1E33),
            background: Color(0xFF0A0E21),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF1D1E33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: Colors.cyanAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          textTheme: GoogleFonts.robotoMonoTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF1D1E33),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
