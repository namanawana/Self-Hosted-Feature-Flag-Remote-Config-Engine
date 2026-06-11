import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature Flag Project',
      theme: ThemeData.dark(),
      home: const FlagListScreen(),
    );
  }
}

class FlagListScreen extends StatefulWidget {
  const FlagListScreen({super.key});

  @override
  State<FlagListScreen> createState() => _FlagListScreenState();
}

class _FlagListScreenState extends State<FlagListScreen> {
  // 🟢 ROOM 1: Your data list MUST live here, outside the build function.
  final List<Map<String, dynamic>> mockFlags = [
    {
      "name": "dark_mode",
      "enabled": true,
      "environment": "production",
      "rule_type": "everyone",
    },
    {
      "name": "beta_dashboard",
      "enabled": false,
      "environment": "staging",
      "rule_type": "beta_only",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 🟢 ROOM 2: Your drawing instructions live here.
    return Scaffold(
      appBar: AppBar(title: const Text('🚩 Feature Flags')),
      body: ListView.builder(
        itemCount: mockFlags.length, // Looks up to Room 1 to find the list size
        itemBuilder: (context, index) {
          final flag = mockFlags[index]; // Grabs an item from the list

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              // We changed ListTile to SwitchListTile!
              child: SwitchListTile(
                // 1. Keeps your beautiful bold flag name
                title: Text(
                  flag["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                // 2. Keeps your environment text underneath
                subtitle: Text("Environment: ${flag["environment"]}"),

                // 3. Reads true or false directly from your mockFlags list!
                value: flag["enabled"],

                // 4. This trigger function runs every single time you click the switch
                onChanged: (bool newValue) {
                  // setState tells Flutter: "Hey, I changed a variable on the chalkboard!
                  // Please quickly redraw the screen so the user sees the switch move."
                  setState(() {
                    mockFlags[index]["enabled"] = newValue;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
