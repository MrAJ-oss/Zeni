// History is now stored server-side per deviceId.
// This service only manages the local display list for the chat UI.

class MemoryService {
  static List<Map<String, String>> _messages = [];

  // Load messages fetched from server into local display list
  static void setMessages(List<Map<String, String>> messages) {
    _messages = List.from(messages);
  }

  // Add a message to local display list
  static void add(String role, String content) {
    _messages.add({"role": role, "content": content});
  }

  // Get all messages for UI display
  static List<Map<String, String>> getMessages() {
    return List.from(_messages);
  }

  // Clear local display list
  static void clear() {
    _messages.clear();
  }

  static int get count => _messages.length;
}