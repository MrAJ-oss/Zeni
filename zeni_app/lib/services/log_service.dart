class LogService {

  static final List<String> logs = [];

  static void add(String text) {

    logs.add(text);

    // ignore: avoid_print
    print("LOG: $text");
  }

  static List<String> getLogs() {

    return logs;
  }

  static void clear() {

    logs.clear();
  }
}