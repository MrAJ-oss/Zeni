class LogService {
  static List<String> logs = [];

  static void add(String log) {
    logs.add("${DateTime.now()} : $log");
  }

  static List<String> getLogs() => logs;

  static void clear() {
    logs.clear();
  }
}