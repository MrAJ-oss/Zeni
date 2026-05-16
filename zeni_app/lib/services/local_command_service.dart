class LocalCommandService {

  static String process(String text) {

    text = text.toLowerCase();

    if (
    text.contains("hello") ||
        text.contains("hi zeni")
    ) {
      return "Hello. I am here.";
    }

    if (
    text.contains("who are you")
    ) {
      return "I am Zeni, your AI assistant.";
    }

    if (
    text.contains("motivate me")
    ) {
      return
      "You are building something bigger than most people even imagine.";
    }

    if (
    text.contains("i am sad")
    ) {
      return
      "I am here with you. Tough days do not last forever.";
    }

    return
    "Internet may be unavailable. Running local mode.";
  }
}