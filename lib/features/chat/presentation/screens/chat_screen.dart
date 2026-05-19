import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:animate_do/animate_do.dart';
import 'package:avatar_glow/avatar_glow.dart';

import '../../domain/models/chat_message.dart';
import '../../data/repositories/sliding_window_memory.dart';
import '../../data/services/react_ai_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _statusText = "";
  
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';

  bool _isPermissionGranted = false;
  late final ReactAiService _aiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Inicializar memoria y servicio
    final memory = SlidingWindowMemory(maxUserInteractions: 3);
    _aiService = ReactAiService(memory);

    _initSpeech();
    _requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status.isGranted && !_isPermissionGranted) {
        setState(() {
          _isPermissionGranted = true;
        });
      }
    }
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: (result) {
      setState(() {
        _lastWords = result.recognizedWords;
        _controller.text = _lastWords;
      });
    });
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
      _statusText = "Iniciando proceso...";
    });

    if (!_isPermissionGranted) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "⚠️ Falta el permiso de archivos. Por favor, acéptalo en la pantalla que se abrirá y luego intenta de nuevo.",
          isUser: false,
        ));
      });
      await _requestPermissions();
      return;
    }

    try {
      final response = await _aiService.processUserRequest(
        text,
        onProgress: (status) {
          setState(() {
            _statusText = status;
          });
        },
      );

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error en el agente IA: $e",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeInDown(child: const Text("Topicos AI Agent")),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: MessageBubble(message: msg),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ),
                  const SizedBox(width: 12),
                  Text(_statusText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                AvatarGlow(
                  animate: _speechToText.isListening,
                  glowColor: Colors.red,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: IconButton(
                    icon: Icon(_speechToText.isNotListening ? Icons.mic_none : Icons.mic),
                    onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe o habla...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
