import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  Future<void> toggleFlag(String flagName) async {
    final url = Uri.parse('http://localhost:8000/flags/$flagName/toggle');
    final response = await http.patch(url);
    if (response.statusCode != 200) {
      throw Exception('ERRORR !! Failed to toggle flag!!');
    }
  }

  late WebSocketChannel channel;
  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8000/ws'));
    channel.stream.listen((message) {
      print(message);
      setState(() {});
    });
  }

  @override
  void dispose() {
    channel.sink.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Flags')),
      body: FutureBuilder<List<dynamic>>(
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
      ),
    );
  }

  Future<List<dynamic>> fetchFlags() async {
    try {
      final url = Uri.parse('http://localhost:8000/flags');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}
