class LocalCommandService {
  static String process(String input) {
    input = input.toLowerCase();

    if (input.contains("time")) {
      return "Current time is ${DateTime.now()}";
    }

    if (input.contains("hello")) {
      return "Hello, I'm Zeni.";
    }

    return "Command not available offline.";
  }
}