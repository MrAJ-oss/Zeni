class MemoryService {
  static List<String> memory = [];

  static void add(String msg) {
    memory.add(msg);

    if (memory.length > 50) {
      memory.removeAt(0);
    }
  }

  static List<String> getAll() => memory;
}