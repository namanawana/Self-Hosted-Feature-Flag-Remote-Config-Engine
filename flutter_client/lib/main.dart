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
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 6, 104, 104),
          brightness: Brightness.dark,
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
          children: [
            const Text('Feature Flags'),
            const SizedBox(width: 14),
            Text(
              isConnected ? "🟢 Connected" : "🟡 Reconnecting...",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateFlagScreen()),
                );
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
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

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class CreateFlagScreen extends StatefulWidget {
  const CreateFlagScreen({super.key});

  @override
  State<CreateFlagScreen> createState() => _CreateFlagScreenState();
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
                    child: ListTile(
                      leading: const Icon(Icons.flag),
                      title: Text(activeFlags[index]["name"]),
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

class _CreateFlagScreenState extends State<CreateFlagScreen> {
  final TextEditingController nameController = TextEditingController();
  String selectedEnvironment = "Development";
  String selectedRule = "everyone";
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Flag")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Flag Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedEnvironment,
              decoration: const InputDecoration(
                labelText: "Environment",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Development",
                  child: Text("Development"),
                ),
                DropdownMenuItem(
                  value: "Production",
                  child: Text("Production"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedEnvironment = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedRule,
              decoration: const InputDecoration(
                labelText: "Rule Type",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "everyone", child: Text("Everyone")),
                DropdownMenuItem(value: "beta_only", child: Text("Beta Users")),
                DropdownMenuItem(
                  value: "percentage",
                  child: Text("Percentage Rollout"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRule = value!;
                });
              },
            ),
            const SizedBox(height: 24),
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
                          await createFlag();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Flag created successfully!"),
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
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
                    : const Text("Create Flag"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createFlag() async {
    final response = await http.post(
      Uri.parse("$baseUrl/flags"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
        "x-api-key": "Aaloo",
      },
      body: jsonEncode({
        "name": nameController.text,
        "enabled": false,
        "environment": selectedEnvironment,
        "rule_type": selectedRule,
        "rule_value": null,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create flag");
    }
  }
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
                      fontSize: 20,
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
