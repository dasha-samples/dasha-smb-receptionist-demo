library

preprocessor digression confirm_intent {
    conditions {
        on digression.confirm_intent.shared.enabled and (#messageHasSentiment("positive") or #messageHasSentiment("negative")) priority 100;
    }    
    shared var enabled: boolean = false;
    shared var confirmed: boolean = true;
    shared var phrase: string = "";
    shared var intent: string = "";

    do {
        set digression.confirm_intent.shared.enabled = false;
        set digression.confirm_intent.shared.confirmed = #messageHasSentiment("positive");
        external updateIntents(digression.confirm_intent.shared.intent, digression.confirm_intent.shared.phrase, digression.confirm_intent.shared.confirmed);
        return;
    }
}
