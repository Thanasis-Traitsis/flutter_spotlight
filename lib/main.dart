import 'package:flutter/material.dart';
import 'widgets/custom_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final backButtonKey = GlobalKey();
  final settingsButtonKey = GlobalKey();
  final exploreButtonKey = GlobalKey();

  bool showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return CustomScreen(
      showOverlay: showOverlay,
      highlightWidgetKeys: [backButtonKey, settingsButtonKey, exploreButtonKey],
      onOverlayTap: () {
        setState(() {
          showOverlay = false;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: backButtonKey,
                onPressed: () {},
                icon: const Icon(Icons.arrow_back),
              ),
              IconButton(
                key: settingsButtonKey,
                onPressed: () {},
                icon: const Icon(Icons.settings),
              ),
            ],
          ),

          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome to the Onboarding Demo",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Follow the steps to learn how to navigate through the app",
                style: TextStyle(fontSize: 18),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    showOverlay = true;
                  });
                },
                child: const Text("Start Highlight"),
              ),
            ],
          ),

          FilledButton(
            key: exploreButtonKey,
            onPressed: () {},
            child: const Text("Explore the app"),
          ),
        ],
      ),
    );
  }
}
