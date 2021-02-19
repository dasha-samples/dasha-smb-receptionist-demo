library

block confirmIntent(question: string, intent: string, probability: number): boolean {
    context {
        text: string?;
    }
    external function updateIntents(intent: string, text: string?, confirmed: boolean): unknown;
    start node confirm {
        do {
            if (#random() < $probability) {
                set $text = #getMessageText();
                #sayText($question);
                wait *;
            } else {
                return true;
            }
        }
        transitions {
            @return: goto @return on true;
        }
    }
    node @return {
        do {
            var confirmed = #messageHasSentiment("positive");
            external updateIntents($intent, $text, confirmed);
            if (!confirmed) {
                #say("repeat_question");
            }
            return confirmed;
        }
    }
}