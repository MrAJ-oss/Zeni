class ToneService {
  static String detectTone(String input) {
    input = input.toLowerCase();

    if (input.contains("angry") || input.contains("hate")) {
      return "angry";
    } else if (input.contains("sad") || input.contains("tired")) {
      return "sad";
    } else if (input.contains("love") || input.contains("happy")) {
      return "happy";
    }

    return "neutral";
  }

  static String modifyResponse(String response, String tone) {
    switch (tone) {
      case "angry":
        return "Hey calm down... $response";
      case "sad":
        return "It's okay... $response";
      case "happy":
        return "Nice! $response";
      default:
        return response;
    }
  }
}