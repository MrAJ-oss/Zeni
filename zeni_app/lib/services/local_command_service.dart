class LocalCommandService {

  static String process(String text) {

    text = text.toLowerCase();

    // Greetings

    if (
    text.contains("hello") ||
        text.contains("hi zeni")
    ) {
      return "Hello. I am here.";
    }

    // Identity

    if (
    text.contains("who are you")
    ) {
      return "I am Zeni, your AI assistant.";
    }

    // Motivation

    if (
    text.contains("motivate me")
    ) {
      return
      "You are building something bigger than most people even imagine.";
    }

    // Emotional

    if (
    text.contains("i am sad")
    ) {
      return
      "I am here with you. Tough days do not last forever.";
    }

    // Offline fallback

    return
    "Internet may be unavailable. Running local mode.";
  }
}