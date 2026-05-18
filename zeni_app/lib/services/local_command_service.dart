class LocalCommandService {

  // Detect if text is a local device command
  static bool isLocalCommand(String text) {
    text = text.toLowerCase();
    return
      text.contains('volume') ||
      text.contains('brightness') ||
      text.contains('flashlight') ||
      text.contains('torch') ||
      text.contains('battery') ||
      text.contains('wifi') ||
      text.contains('wi-fi') ||
      text.contains('bluetooth') ||
      text.contains('go home') ||
      text.contains('home screen') ||
      text.contains('open downloads') ||
      text.contains('open files') ||
      text.contains('my files') ||
      text.contains('open settings') ||
      text.contains('set alarm') ||
      text.contains('wake me') ||
      text.contains('install ') ||
      text.contains('screenshot') ||
      text.contains('mute') ||
      text.contains('unmute') ||
      text.contains('call ') ||
      text.contains('new tab') ||
      text.contains('close tab') ||
      (text.contains('open ') && !text.contains('open a') && !text.contains('open the topic')) ||
      text.contains('search ') ||
      text.contains('youtube ') ||
      text.contains('play ');
  }

  // Basic offline personality responses (when truly offline and not a device command)
  static String offlineResponse(String text) {
    text = text.toLowerCase();

    if (text.contains('hello') || text.contains('hi zeni')) {
      return "Hello. I am here.";
    }
    if (text.contains('who are you')) {
      return "I am Zeni, your personal AI assistant.";
    }
    if (text.contains('motivate me') || text.contains('motivation')) {
      return "You are building something bigger than most people even imagine. Keep going.";
    }
    if (text.contains('i am sad') || text.contains('feeling sad')) {
      return "I am here with you. Tough days do not last forever.";
    }
    if (text.contains('i am happy') || text.contains('feeling happy')) {
      return "That is great to hear. Keep that energy going.";
    }
    if (text.contains('thank you') || text.contains('thanks')) {
      return "Always here for you.";
    }
    if (text.contains('what time') || text.contains('current time')) {
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : now.hour;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      return "It is $hour:$minute $period.";
    }
    if (text.contains('what day') || text.contains('today')) {
      final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      final day = days[DateTime.now().weekday - 1];
      return "Today is $day.";
    }

    return "I need internet to answer that. I am running in offline mode.";
  }
}