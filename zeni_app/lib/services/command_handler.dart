class CommandHandler {
  static String? handle(String text) {
    text = text.toLowerCase();

    if (text.contains("call mom")) {
      return "CALL_MOM";
    }

    if (text.contains("open youtube")) {
      return "OPEN_YOUTUBE";
    }

    if (text.contains("open whatsapp")) {
      return "OPEN_WHATSAPP";
    }

    return null; // send to AI if no match
  }
}