library

block confirmIntent(question: string, intent: string, probability: number, du_text: string?): boolean {
    context {
        text: string?;
    }
    external function updateIntents(intent: string, text: string?, confirmed: boolean): unknown;
    start node confirm {
        do {
            if($du_text is not null && $du_text != "") {
                //#log("adding new du_text");
                //#log($du_text);
                external updateIntents($intent, $du_text, true);
                set $du_text = null;
            }

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