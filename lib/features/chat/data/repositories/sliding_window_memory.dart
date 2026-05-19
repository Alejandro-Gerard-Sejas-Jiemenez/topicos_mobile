import '../../domain/models/memory_message.dart';

class SlidingWindowMemory {
  final List<MemoryMessage> _messages = [];
  final int maxUserInteractions;

  SlidingWindowMemory({this.maxUserInteractions = 3});

  void addMessage(MemoryMessage message) {
    _messages.add(message);
    _pruneMemory();
  }

  void _pruneMemory() {
    int userMessageCount = _messages.where((m) => m.role == MemoryRole.user).length;
    
    while (userMessageCount > maxUserInteractions) {
      // Find the index of the first user message
      final firstUserIndex = _messages.indexWhere((m) => m.role == MemoryRole.user);
      if (firstUserIndex == -1) break;

      // Find the index of the second user message
      final secondUserIndex = _messages.indexWhere((m) => m.role == MemoryRole.user, firstUserIndex + 1);
      
      if (secondUserIndex != -1) {
        // Remove everything up to the second user message
        _messages.removeRange(0, secondUserIndex);
      } else {
        // If there is no second user message (shouldn't happen based on the count, but for safety)
        _messages.removeAt(firstUserIndex);
      }
      
      userMessageCount = _messages.where((m) => m.role == MemoryRole.user).length;
    }
  }

  String getFormattedHistory() {
    if (_messages.isEmpty) return "No hay historial.";
    
    final buffer = StringBuffer();
    for (var msg in _messages) {
      buffer.writeln(msg.toFormattedString());
    }
    return buffer.toString().trim();
  }

  void clear() {
    _messages.clear();
  }
}
