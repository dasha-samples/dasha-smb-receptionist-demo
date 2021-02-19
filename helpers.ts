import { AudioRecord, IChatChannel } from "@dasha.ai/platform-sdk";
import * as fs from "fs";
import * as readline from "readline";
import Path from "path";

export function createLogger(options?: {
  log?: typeof console.log;
  logFile?: string;
}) {
  const appendLog = async (str: string) => {
    if (options?.logFile) {
      await fs.promises.appendFile(options.logFile, str);
    }
  }
  appendLog(`${"#".repeat(100)}\n`);
  return {
    log: async (msg: string) => {
      options?.log?.({ Log: msg });
      await appendLog(`Log: ${msg}\n`);
    },
    transcription: async (msg: string, incoming: boolean) => {
      options?.log?.(incoming ? { Human: msg } : { AI: msg });
      await appendLog(incoming ? `Human: ${msg}\n` : `AI: ${msg}\n`);
    },
    raw: async (devlog: any) => {
      if (devlog.msg.msgId === "RecognizedSpeechMessage") {
        await appendLog(JSON.stringify(devlog.msg.results[0]?.facts, undefined, 2) + "\n");
      }
    }
  }
}

export function recordToUrl(record: AudioRecord) {
  return `https://dasha-call-records-public-beta.s3.amazonaws.com/${record.recordId}/call.mp3`;
}

export async function runConsoleChat(chatChannel: IChatChannel) {
  const cli = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  console.log("Chat opened");
  let closed = false;
  chatChannel.receivedMessages.subscribe({
    next: (text) => {
      console.log("AI:", text);
    },
    complete: () => {
      closed = true;
      console.log("Chat closed");
    },
    error: (error) => {
      closed = true;
      console.warn("Chat error:", error);
    },
  });

  for await (const line of cli) {
    if (closed || line === "") {
      await chatChannel.close();
      break;
    } else {
      await chatChannel.sendMessage(line);
    }
  }

  cli.close();
}

export const UPDATE_INTENTS_FILE = "update_intents";

export function removeUpdateIntentsFile() {
  return fs.promises.unlink(UPDATE_INTENTS_FILE).catch(()=>{});
}

interface ICustomIntents {
  includes?: Partial<Record<string, string[]>>;
  excludes?: Partial<Record<string, string[]>>;
}

async function getCustomIntentsFile(appPath: string): Promise<string> {
  const appDirContent = await fs.promises.readdir(appPath);
  const dashaappFile = appDirContent.find((file) => Path.extname(file) === ".dashaapp");
  if (dashaappFile === undefined) throw new Error("Cannot update intents: .dashaapp file not found");
  const dashaappFileContent = await fs.promises.readFile(Path.join(appPath, dashaappFile));
  const dashaapp = JSON.parse(dashaappFileContent.toString());
  const intentsFile: string | undefined = dashaapp?.nlu?.customIntents?.file;
  if (intentsFile === undefined) throw new Error("Cannot update intents: custom intents file not found"); 
  return Path.join(appPath, intentsFile);
}

async function getCustomIntents(intentsPath: string): Promise<ICustomIntents> {
  const intentsContent = await fs.promises.readFile(intentsPath);
  return JSON.parse(intentsContent.toString());
}

async function applyUpdateCustomIntents(intents: ICustomIntents): Promise<ICustomIntents> {
  for await (const line of readline.createInterface(fs.createReadStream(UPDATE_INTENTS_FILE))) {
    const parsedLine = /^(.*?) (.*?) (.*)$/.exec(line) ?? [];
    const type: keyof typeof intents | undefined = parsedLine[1] as keyof typeof intents;
    const intent: string | undefined = parsedLine[2];
    const phrase: string | undefined = parsedLine[3];
    //console.log(parsedLine, intent, type, phrase);
    if (intent === undefined || type === undefined || phrase === undefined) {
      console.error("Cannot parse line", line);
      continue;
    }
    intents[type] ??= {};
    intents[type]![intent] ??= [];
    intents[type]![intent]!.push(phrase);
  }

  return intents;
}

function fixCustomIntents(intents: ICustomIntents): ICustomIntents {
  const dups: Partial<Record<string, string[]>> = {};
  for (const intent in intents.includes) {
    dups[intent] = intents.includes[intent]?.filter((phrase) => intents.excludes?.[intent]?.includes(phrase));
  }
  for (const type in intents) {
    const t = type as keyof typeof intents;
    for (const intent in intents[t]) {
      intents[t]![intent] = [... new Set(intents[t]![intent]?.filter((phrase) => !dups[intent]?.includes(phrase)) ?? [])];
      if ((intents[t]![intent]?.length ?? 0) === 0) delete intents[t]![intent];
    }
  }
  return intents;
}

async function backupCustomIntents(intentsFile: string) {
  const old_intents = "old_intents";
  const now = new Date(Date.now());
  const nowString = [
    now.getFullYear(), 
    now.getMonth(), 
    now.getDate(), 
    now.getHours(), 
    now.getMinutes(),
    now.getSeconds()
  ].join("-");
  if (!fs.existsSync(old_intents)) await fs.promises.mkdir(old_intents);
  return fs.promises.copyFile(intentsFile, Path.join(old_intents, nowString))
}

function writeCustomIntents(intentsPath: string, intents: ICustomIntents) {
  return fs.promises.writeFile(intentsPath, JSON.stringify(intents, undefined, 2));
}

export async function updateCustomIntents(appPath: string) {
  if (!fs.existsSync(UPDATE_INTENTS_FILE)) return;
  const intentsFile = await getCustomIntentsFile(appPath);
  const updatedIntents = await getCustomIntents(intentsFile).then(applyUpdateCustomIntents);
  removeUpdateIntentsFile();
  const intents = fixCustomIntents(updatedIntents);
  await backupCustomIntents(intentsFile);
  await writeCustomIntents(intentsFile, intents);
}