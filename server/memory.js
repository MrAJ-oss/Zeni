let memory = {
  name: "Anuj",
  history: []
};

function log(text, action) {
  memory.history.push({ text, action, time: new Date() });
}

module.exports = { memory, log };