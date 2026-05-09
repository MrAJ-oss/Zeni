class MemoryService {

  static final List<String> _memory = [];

  static void add(String text) {

    _memory.add(text);

    // ignore: avoid_print
    print("Memory added: $text");
  }

  static List<String> getAll() {

    return _memory;
  }

  static void clear() {

    _memory.clear();
  }
}