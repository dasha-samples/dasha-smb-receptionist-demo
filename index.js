const fs = require("fs");

const dasha = require("@dasha.ai/sdk");

function updateCustomIntents() {
  if (!fs.existsSync("./update_intents")) return;

  const intents = JSON.parse(fs.readFileSync("./app/intents.json", "utf-8"));
  const intentUpdates = fs.readFileSync("./update_intents", "utf-8").split("\n");

  for (const intentUpdate of intentUpdates) {
    const [type, intent, phrase] = intentUpdate.split(" ", 3);
    if (!intents[type]) intents[type] = {};
    if (!intents[type][intent]) intents[type][intent] = [];
    intents[type][intent].push(phrase);
  }

  const dups = {};

  for (const intent of Object.keys(intents.includes)) {
    dups[intent] = intents.includes[intent]?.filter((phrase) =>
      intents.excludes?.[intent]?.includes(phrase)
    );
  }

  for (const type of Object.keys(intents)) {
    for (const intent in intents[t]) {
      intents[type][intent] = [
        ...new Set(intents[t][intent]?.filter((phrase) => !dups[intent]?.includes(phrase)) ?? []),
      ];
      if ((intents[type][intent]?.length ?? 0) === 0) delete intents[type][intent];
    }
  }

  fs.unlinkSync("./update_intents");

  fs.mkdirSync("./old_intents", { recursive: true });
  fs.renameSync(
    "./app/intents.json",
    "./old_intents/${new Date().toISOString().replace(/:/g, "-")}"
  );

  fs.writeFileSync("./app/intents.json", JSON.stringify(intents, undefined, 2));
}

async function main() {
  if (!process.argv[2]) {
    console.log("no phone specified");
    process.exitCode = 1;
    return;
  }

  if (fs.existsSync("./update_intents")) {
    fs.unlinkSync("./update_intents");
  }

  const app = await dasha.deploy("./app");

  app.ttsDispatcher = () => "dasha";

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));

  app.setExternal("updateIntents", async ({ intent, text, confirmed }) => {
    if (!text) return;
    await fs.promises.appendFile(
      "./update_intents",
      `${confirmed ? "includes" : "excludes"} ${intent} ${text}\n`
    );
  });

  await app.start();

  const conv = app.createConversation({ phone: process.argv[2] });

  if (conv.input.phone !== "chat") conv.on("transcription", console.log);

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  await conv.execute();

  updateCustomIntents();

  await app.stop();
  app.dispose();

  await logFile.close();
}

main();
