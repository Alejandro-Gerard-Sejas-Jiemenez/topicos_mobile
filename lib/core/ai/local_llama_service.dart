import 'dart:io';
import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

class LocalLlamaService {
  bool _isInitialized = false;
  late LlamaEngine _engine;
  String _lastResponse = "";
  bool _isGenerating = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("--- INICIANDO MOTOR LLAMADART (AUTO-BINARY) ---");
      
      const String downloadPath = '/storage/emulated/0/Download';
      const String modelRelativePath = 'models/gemma-2-2b-it-Q4_K_M.gguf'; 
      final String modelPath = '$downloadPath/$modelRelativePath';
      
      if (!await File(modelPath).exists()) {
        print("ERROR: Modelo no encontrado en $modelPath");
        throw Exception("Modelo GGUF no encontrado en $modelPath.");
      }

      // 1. Inicializar el motor con el backend por defecto
      _engine = LlamaEngine(LlamaBackend());
      
      print("Cargando modelo en el motor (Modo LIGERO)...");
      // En llamadart v0.6.x, los parámetros se pasan al cargar el modelo
      await _engine.loadModel(
        modelPath,
        modelParams: ModelParams(
          gpuLayers: 0,
          contextSize: 1280,
          numberOfThreads: 4,
        ),
      );

      _isInitialized = true;
      print("Motor llamadart inicializado con éxito.");
    } catch (e) {
      print("Error crítico inicializando llamadart: $e");
      rethrow;
    }
  }

  Future<String> generate(String prompt) async {
    if (!_isInitialized) await initialize();
    
    _lastResponse = "";
    _isGenerating = true;

    print("--- INICIANDO GENERACIÓN LLAMADART ---");
    
    // 2. Cargar Gramática GBNF para la generación
    String? grammar;
    try {
      grammar = await rootBundle.loadString('assets/grammar/output.gbnf');
    } catch (e) {
      print("Aviso: No se pudo cargar la gramática: $e");
    }

    // 3. Configurar parámetros (Desactivamos gramática para probar estabilidad)
    final params = GenerationParams(
      grammar: null, 
      temp: 0.2,
    );

    // 4. Generar tokens
    try {
      await for (final token in _engine.generate(prompt, params: params)) {
        _lastResponse += token;
      }
    } catch (e) {
      print("Error durante la generación: $e");
    }

    _isGenerating = false;
    print("--- RESPUESTA RECIBIDA ---");
    print(_lastResponse);
    return _lastResponse;
  }

  void dispose() {
    _engine.dispose();
  }
}
