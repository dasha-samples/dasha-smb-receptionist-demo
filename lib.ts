import * as fs from "fs";
import { UPDATE_INTENTS_FILE } from "./helpers";

interface IArgs extends Record<string, unknown> {
    intent: string;
    text: string | null;
    confirmed: boolean;
}

export async function updateIntents({ intent, text, confirmed }: IArgs): Promise<unknown> {
    if (text === null) return;
    fs.promises.appendFile(UPDATE_INTENTS_FILE, `${confirmed ? "includes" : "excludes"} ${intent} ${text}\n`);
    return null;
}