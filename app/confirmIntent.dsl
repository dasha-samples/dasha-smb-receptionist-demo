library
import "confirmIntentPreprocessor.dsl";

digression repeat_question {
    conditions {
        on digression.confirm_intent.shared.confirmed == false priority -50;
    }

    var repeat_question: Phrases[] = ["repeat_question"];

    do {
        set digression.confirm_intent.shared.confirmed = true;
        for (var phrase in digression.repeat_question.repeat_question) {
            #say(phrase);
        }
        wait *;
    }
}

block confirmIntent(question: string, intent: string, probability: number, du_text: string?): boolean {
    import "confirmIntentPreprocessor.dsl";
    
    start node confirm {
        do {
            if($du_text is not null && $du_text != "") {
                external updateIntents($intent, $du_text, true);
            }
            if (#random() < $probability) {
                set digression.confirm_intent.shared.enabled = true;
                set digression.confirm_intent.shared.confirmed = true;
                set digression.confirm_intent.shared.phrase = #getMessageText();
                set digression.confirm_intent.shared.intent = $intent;
                #sayText($question);
                return true;
            }
            return false;
        }
    }
}