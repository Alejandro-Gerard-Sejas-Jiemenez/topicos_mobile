import 'dart:convert';
import 'package:http/http.dart' as http;

class ActionExecutor {
  final String baseUrl = "https://serverlest-topicos-gateway-8zoia048.uc.gateway.dev";

  Future<String> executeAction(Map<String, dynamic> action) async {
    final method = action['method']?.toString().toUpperCase() ?? 'GET';
    final endpoint = action['endpoint'] ?? '';
    final data = action['data'] ?? {};
    
    // Asegurar que solo haya una barra entre base y endpoint
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : "/$endpoint";
    
    final url = Uri.parse("$cleanBase$cleanEndpoint");
    print("--- LLAMADA API ($method): $url ---");
    
    try {
      late http.Response response;

      if (method == 'GET') {
        response = await http.get(url);
      } else if (method == 'POST') {
        response = await http.post(url, body: jsonEncode(data), headers: {"Content-Type": "application/json"});
      } else if (method == 'PUT') {
        response = await http.put(url, body: jsonEncode(data), headers: {"Content-Type": "application/json"});
      } else if (method == 'DELETE') {
        response = await http.delete(url, body: jsonEncode(data), headers: {"Content-Type": "application/json"});
      } else {
         return "Error: Método HTTP no soportado: $method";
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _summarizeSuccess(response.body, action['operation']);
      } else {
        return "Error API (${response.statusCode}): ${_summarizeError(response.body)}";
      }
    } catch (e) {
      return "Error de red ejecutando acción: $e";
    }
  }

  // Resumir el JSON de forma compacta e inteligente para no agotar tokens de memoria
  String _summarizeSuccess(String rawResponse, String? operation) {
    try {
      final decoded = jsonDecode(rawResponse);
      
      if (decoded is Map) {
        String summary = "Éxito.";
        if (decoded.containsKey('message')) {
          summary += " Mensaje: ${decoded['message']}.";
        }
        
        // Extraer los datos reales del payload
        dynamic content = decoded.containsKey('data') ? decoded['data'] : decoded;

        if (content is List) {
          final compactList = content.map((item) {
            if (item is Map) {
              // Mantener solo los campos representativos filtrando metadatos temporales
              final cleanItem = Map.from(item)..removeWhere((k, v) => 
                k.toString().contains('created_at') || 
                k.toString().contains('updated_at')
              );
              return cleanItem.toString();
            }
            return item.toString();
          }).toList();
          
          summary += " Datos obtenidos (${content.length} registros): $compactList";
        } else if (content is Map) {
          final cleanItem = Map.from(content)..removeWhere((k, v) => 
            k.toString().contains('created_at') || 
            k.toString().contains('updated_at')
          );
          summary += " Datos: $cleanItem";
        } else {
          if (decoded.containsKey('id')) {
             summary += " ID: ${decoded['id']}.";
          }
        }
        
        return summary;
      }
      
      return "Acción ejecutada con éxito (Respuesta no estándar).";
    } catch (_) {
      // Si no es JSON pero fue exitoso
      if (rawResponse.trim().isEmpty) return "Acción ejecutada con éxito.";
      return "Éxito. Respuesta: ${rawResponse.length > 80 ? rawResponse.substring(0, 80) + '...' : rawResponse}";
    }
  }

  String _summarizeError(String rawResponse) {
    try {
      final decoded = jsonDecode(rawResponse);
      if (decoded is Map && decoded.containsKey('error')) {
        return decoded['error'].toString();
      } else if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return rawResponse.length > 50 ? rawResponse.substring(0, 50) + "..." : rawResponse;
  }
}
