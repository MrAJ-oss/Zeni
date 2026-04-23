function generateReply(name, text, cmd) {
  if (cmd) {
    return `Hey ${name}, executing ${cmd}`;
  }
  return `Hey ${name}, I didn’t understand that`;
}

module.exports = { generateReply };