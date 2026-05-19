import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class OpenApiParser {
  static Future<String> getToolsPrompt(String assetPath) async {
    try {
      final String yamlString = await rootBundle.loadString(assetPath);
      final dynamic doc = loadYaml(yamlString);
      
      if (doc == null || doc['paths'] == null) return "No tools found.";

      final StringBuffer buffer = StringBuffer();
      final Map<dynamic, dynamic> paths = doc['paths'];

      paths.forEach((path, methods) {
        if (methods is Map) {
          methods.forEach((method, details) {
            if (details is Map) {
              final String operationId = details['operationId'] ?? path.split('/').last;
              
              // Intentar extraer el módulo del primer tag
              String module = "general";
              if (details['tags'] != null && details['tags'] is List && details['tags'].isNotEmpty) {
                module = details['tags'][0].toString().toLowerCase();
              } else {
                // Si no hay tags, usar la primera parte del path
                final parts = path.toString().split('/');
                if (parts.length > 1) module = parts[1];
              }

              final String summary = details['summary'] ?? "";
              
              buffer.writeln("- module: $module, operation: $operationId, method: ${method.toString().toUpperCase()}, endpoint: $path, $summary");
            }
          });
        }
      });

      return buffer.toString();
    } catch (e) {
      print("Error parseando OpenAPI: $e");
      return "Error loading tools.";
    }
  }
}
