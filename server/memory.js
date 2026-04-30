let memory = {
  name: null,
  history: []
};

export function setName(name) {
  memory.name = name;
}

export function getName() {
  return memory.name;
}

export function addMessage(role, text) {
  memory.history.push({ role, text });

  if (memory.history.length > 50) {
    memory.history.shift();
  }
}

export function getHistory() {
  return memory.history;
}