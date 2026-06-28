//Self-Hosted-Feature-Flag-Remote-Config-Engine
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const String baseUrl = "https://landing-traffic-sixteen.ngrok-free.dev";
const String wsUrl = "ws://landing-traffic-sixteen.ngrok-free.dev/ws";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature Flag Project',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071A1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E3B3B),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF123D3D),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 3, 164, 70),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  bool isConnected = false;
  late WebSocketChannel channel;
  final screens = [const FlagListScreen(), const ConfigScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "🚩 Feature Flags",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withValues(alpha: 0.18)
                    : Colors.orange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: isConnected
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(isConnected ? "Connected" : "Reconnecting"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
      persistentFooterButtons: [
        if (selectedIndex == 0)
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EvaluateUserScreen()),
              );
            },
          ),
      ],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Feature Flags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuration Settings',
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void connectWebSocket() {
    if (isConnected) return;
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    setState(() {
      isConnected = true;
    });
    channel.stream.listen(
      (message) {
        print("WEBSOCKET: $message");
      },
      onDone: () {
        setState(() {
          isConnected = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          connectWebSocket();
        });
      },
      onError: (error) {
        setState(() {
          isConnected = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Server unavailable. Reconnecting..."),
            ),
          );
        }
        Future.delayed(const Duration(seconds: 3), () {
          connectWebSocket();
        });
      },
    );
  }
}

class FlagListScreen extends StatefulWidget {
  const FlagListScreen({super.key});
  @override
  State<FlagListScreen> createState() => _FlagListScreenState();
}

class _FlagListScreenState extends State<FlagListScreen> {
  Future<void> toggleFlag(String flagName) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/flags/$flagName/toggle"),
      headers: {
        "ngrok-skip-browser-warning": "true",
        "Content-Type": "application/json",
        "x-api-key": "Aaloo",
      },
    );

    print("Status Code: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to toggle flag");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchFlags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final flags = snapshot.data!;

        return ListView.builder(
          itemCount: flags.length,
          itemBuilder: (context, index) {
            final flag = flags[index];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: flag["enabled"]
                      ? Colors.greenAccent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      flag["enabled"] ? Icons.verified : Icons.flag_outlined,
                      color: flag["enabled"] ? Colors.greenAccent : Colors.grey,
                      size: 32,
                    ),
                    title: Text(
                      flag["name"],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                    subtitle: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.public,
                            size: 18,
                            color: Colors.white,
                          ),
                          backgroundColor: flag["rule_type"] == "everyone"
                              ? Colors.green
                              : flag["rule_type"] == "beta_only"
                              ? Colors.blue
                              : Colors.orange,
                          label: Text(
                            flag["environment"],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.rule,
                            size: 18,
                            color: Colors.white,
                          ),
                          backgroundColor: Colors.green,
                          label: Text(
                            flag["rule_type"] == "everyone"
                                ? "Everyone"
                                : flag["rule_type"] == "beta_only"
                                ? "Beta Users"
                                : "${flag["rule_value"]}% Rollout",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    value: flag["enabled"],
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.greenAccent;
                      }
                      return Colors.grey;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.teal;
                      }
                      return Colors.grey.shade700;
                    }),
                    onChanged: (bool newValue) async {
                      try {
                        await toggleFlag(flag["name"]);
                        setState(() {});
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> fetchFlags() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/flags"),
        headers: {
          "ngrok-skip-browser-warning": "true",
          "Content-Type": "application/json",
          "x-api-key": "Aaloo",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  Future<List<dynamic>> fetchConfigs() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/config"),
        headers: {
          "ngrok-skip-browser-warning": "true",
          "Content-Type": "application/json",
          "x-api-key": "Aaloo",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("Server returned ${response.statusCode}");
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  Future<void> updateConfig(String key, String value) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/config/$key"),
      headers: {
        "ngrok-skip-browser-warning": "true",
        "Content-Type": "application/json",
        "x-api-key": "Aaloo",
      },
      body: jsonEncode({"value": value}),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update config");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchConfigs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final configs = snapshot.data!;
        return ListView.builder(
          itemCount: configs.length,
          itemBuilder: (context, index) {
            final config = configs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                onTap: () async {
                  final controller = TextEditingController(
                    text: config["value"].toString(),
                  );
                  final newValue = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Update ${config['key']}"),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: "New Value",
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text),
                          child: const Text("Update"),
                        ),
                      ],
                    ),
                  );
                  if (newValue != null) {
                    await updateConfig(config["key"], newValue);
                    setState(() {});
                  }
                },
                title: Text(
                  config["key"],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                subtitle: Text(config["description"]),
                trailing: Text(config["value"].toString()),
              ),
            );
          },
        );
      },
    );
  }
}

class EvaluateUserScreen extends StatefulWidget {
  const EvaluateUserScreen({super.key});

  @override
  State<EvaluateUserScreen> createState() => _EvaluateUserScreenState();
}

class _EvaluateUserScreenState extends State<EvaluateUserScreen> {
  final TextEditingController userIdController = TextEditingController();
  List<dynamic> activeFlags = [];
  bool isLoading = false;
  Future<void> evaluateUser() async {
    final response = await http.post(
      Uri.parse("$baseUrl/evaluate"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
        "x-api-key": "Aaloo",
      },
      body: jsonEncode({"user_id": userIdController.text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        activeFlags = data["active_flags"];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User evaluated successfully!")),
      );
    } else {
      throw Exception("Failed to evaluate user");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evaluate User")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: "User ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          await evaluateUser();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Evaluate"),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Active Flags",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: activeFlags.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(
                        Icons.flag,
                        color: Colors.greenAccent,
                      ),
                      title: Text(
                        activeFlags[index]["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
