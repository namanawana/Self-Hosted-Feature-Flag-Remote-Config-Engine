import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
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
      theme: ThemeData.dark(),
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
          children: [
            const Text('Feature Flags'),
            const SizedBox(width: 14),
            Text(
              isConnected ? '🟢 Connected!' : '🔴 Disconnected!',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
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
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    setState(() {
      isConnected = true;
      void connectWebSocket() {
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
          },
          onError: (error) {
            setState(() {
              isConnected = false;
            });
          },
        );
      }
    });
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
              child: ListTile(
                onTap: () async {
                  final controller = TextEditingController(
                    text: config["value"].toString(),
                  );
                },
                title: Text(
                  config["key"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SwitchListTile(
                  title: Text(
                    flag["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text("Environment: ${flag["environment"]}"),
                  value: flag["enabled"],
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
          "x-api-key": "Aaloo", // Day 6 API Key protection match
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
