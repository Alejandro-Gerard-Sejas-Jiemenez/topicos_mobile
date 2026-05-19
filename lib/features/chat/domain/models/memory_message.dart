enum MemoryRole {
  user,       // The human user
  assistant,  // The LLM returning a final text response to the user
  action,     // The LLM returning a tool call (JSON)
  observation // The system returning the result of a tool call
}

class MemoryMessage {
  final MemoryRole role;
  final String content;

  MemoryMessage({required this.role, required this.content});

  String toFormattedString() {
    switch (role) {
      case MemoryRole.user:
        return "Usuario: $content";
      case MemoryRole.assistant:
        return "Asistente: $content";
      case MemoryRole.action:
        return "Acción IA: $content";
      case MemoryRole.observation:
        return "Resultado Backend: $content";
    }
  }

  @override
  String toString() => toFormattedString();
}
