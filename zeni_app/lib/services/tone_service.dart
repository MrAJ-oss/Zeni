class ToneService {

  static String detectTone(String text) {

    text = text.toLowerCase();

    if (
    text.contains("sad") ||
        text.contains("depressed") ||
        text.contains("upset")
    ) {
      return "sad";
    }

    if (
    text.contains("angry") ||
        text.contains("mad")
    ) {
      return "angry";
    }

    if (
    text.contains("happy") ||
        text.contains("excited")
    ) {
      return "happy";
    }

    return "normal";
  }

  static String modifyResponse(
      String response,
      String tone,
      ) {

    switch (tone) {

      case "sad":
        return "I am here for you. $response";

      case "angry":
        return "Take it easy. $response";

      case "happy":
        return "That sounds awesome! $response";

      default:
        return response;
    }
  }
}