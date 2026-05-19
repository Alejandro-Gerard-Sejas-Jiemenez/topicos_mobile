import 'package:flutter/material.dart';
import 'features/chat/presentation/screens/chat_screen.dart';

void main() {
  runApp(const TopicosApp());
}

class TopicosApp extends StatelessWidget {
  const TopicosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topicos LLM Router',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
