import 'dart:convert';
import '../../../../core/utils/openapi_parser.dart';
import '../../../../core/ai/local_llama_service.dart';
import '../../../../core/network/action_executor.dart';
import '../../domain/models/memory_message.dart';
import '../repositories/sliding_window_memory.dart';

class ReactAiService {
  final LocalLlamaService _llama = LocalLlamaService();
  final ActionExecutor _executor = ActionExecutor();
  final SlidingWindowMemory memory;
  String? _cachedTools;

  ReactAiService(this.memory);

  Future<String> _getPrompt(String newUserInput) async {
    _cachedTools ??= await OpenApiParser.getToolsPrompt(
      'assets/api/openapi.yaml',
    );

    final history = memory.getFormattedHistory();

    return """
<start_of_turn>user
You are a smart JSON parsing agent and API executor.
Your task is to help the user by calling the correct APIs based on their request.

TOOLS AVAILABLE:
$_cachedTools

RULES:
1. If you need to perform an action, output a JSON list of objects:
[{"module": string, "operation": string, "method": string, "endpoint": string, "data": object}]
2. Use EXACT 'method' and 'endpoint' from the tools list.
3. If you have already executed the necessary actions and have the observations, OR if the user is just chatting and no tool is needed, respond with normal conversational text explaining the result. DO NOT output JSON if you are finished.

CONVERSATION HISTORY:
$history
<end_of_turn>
<start_of_turn>model
""";
  }

  /// Processes the user input automatically:
  /// 1. Adds user message to memory.
  /// 2. Asks the LLM.
  /// 3. If LLM gives actions, executes them, adds observations to memory, and repeats.
  /// 4. If LLM gives text, adds it to memory as assistant and returns it.
  Future<String> processUserRequest(
    String userInput, {
    Function(String status)? onProgress,
  }) async {
    // 1. Añadir el mensaje del usuario a la memoria
    memory.addMessage(MemoryMessage(role: MemoryRole.user, content: userInput));
    
    int loopCount = 0;
    const maxLoops = 3; // Evitar bucles infinitos
    
    String finalResponse = "No pude procesar la solicitud.";

    while (loopCount < maxLoops) {
      loopCount++;
      onProgress?.call("Pensando (Paso $loopCount)...");
      
      final prompt = await _getPrompt(userInput); // userInput here is just to show in the prompt, but actually history has it. Let's adjust prompt to use history mostly.
      final response = await _llama.generate(prompt);
      
      print("--- RESPUESTA GEMMA (Ciclo $loopCount) ---");
      print(response);
      print("----------------------------------");

      final actions = _cleanAndParseResponse(response);
      
      if (actions.isNotEmpty) {
         // La IA decidió ejecutar herramientas
         memory.addMessage(MemoryMessage(role: MemoryRole.action, content: jsonEncode(actions)));
         
         onProgress?.call("Ejecutando ${actions.length} acción(es)...");
         
         final List<String> observations = [];
         for (var action in actions) {
            final obs = await _executor.executeAction(action as Map<String, dynamic>);
            observations.add(obs);
         }
         
         final obsText = observations.join("\n");
         memory.addMessage(MemoryMessage(role: MemoryRole.observation, content: obsText));
         
         // El ciclo se repite para que la IA lea la observación y decida el siguiente paso
         continue;
      } else {
         // La IA respondió con texto normal (respuesta final)
         String cleanedText = response.trim();
         // Limpiar posibles etiquetas residuales
         cleanedText = cleanedText.replaceAll("<start_of_turn>model\n", "").replaceAll("<end_of_turn>", "");
         
         if (cleanedText.isEmpty) {
            cleanedText = "Tarea completada.";
         }
         
         memory.addMessage(MemoryMessage(role: MemoryRole.assistant, content: cleanedText));
         finalResponse = cleanedText;
         break; // Fin del ciclo
      }
    }

    if (loopCount >= maxLoops) {
      finalResponse = "He alcanzado el límite de operaciones. Revisa los resultados.";
      memory.addMessage(MemoryMessage(role: MemoryRole.assistant, content: finalResponse));
    }

    return finalResponse;
  }

  List<dynamic> _cleanAndParseResponse(String text) {
    String cleaned = text.trim();
    cleaned = cleaned.replaceAll("<start_of_turn>model\n", "");
    cleaned = cleaned.replaceAll("<end_of_turn>", "");

    if (cleaned.startsWith("```")) {
      final lines = cleaned.split("\n");
      if (lines.first.startsWith("```")) lines.removeAt(0);
      if (lines.isNotEmpty && lines.last.startsWith("```")) lines.removeLast();
      cleaned = lines.join("\n").trim();
    }

    cleaned = cleaned.replaceAll(RegExp(r',\s*\]'), ']');
    cleaned = cleaned.replaceAll(RegExp(r',\s*\}'), '}');

    try {
      // Si logra parsear una lista válida, es una acción
      final parsed = json.decode(cleaned);
      if (parsed is List) return parsed;
      return [];
    } catch (e) {
      // Si no es JSON, asumimos que es texto de respuesta final
      return [];
    }
  }
}
