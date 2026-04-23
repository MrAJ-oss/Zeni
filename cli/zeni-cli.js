const readline = require("readline");
const axios = require("axios");

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function ask() {
  rl.question("YOU: ", async (input) => {
    const res = await axios.post("http://localhost:3000/api/voice", {
      text: input
    });

    console.log("ZENI:", res.data.reply);
    ask();
  });
}

ask();