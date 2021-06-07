context {
    input phone: string;
    desired_weekday: string = "";
}

start node root {
    do {
        #connectSafe($phone);
        #waitForSpeech(1000);
        #sayText("Church's Barbershop and Sodapop! How can I help you?");
        wait *;
    }    
}

digression schedule_haircut {
    conditions {on #messageHasIntent("schedule_haircut");}
    do {
        #sayText("You want to get a haircut, did I hear you correctly?");
        wait *;
    }
    transitions {
        schedule_haircut_day: goto schedule_haircut_day on #messageHasSentiment("positive");
        this_is_barbershop: goto this_is_barbershop on #messageHasSentiment("negative");
    }
}

node schedule_haircut_day {
    do {
        #sayText("Okay. What day would you like to come in?");
        wait *;
    }
}

node this_is_barbershop {
    do {
        #sayText("You called a barbershop but you don't want a haircut. Call back when you do want one then. Bahumbug.");
        #disconnect();
        exit;
    }
}

digression schedule_weekday {
    conditions { on #messageHasAnyIntent(["monday", "tuesday", "wednesday", "thursday", "friday", "sunday", "saturday"]); }
    do  {
        #sayText("Let me just check the books...");

        if(#messageHasIntent("monday")) { set $desired_weekday = "monday"; }
        else if(#messageHasIntent("tuesday")) { set $desired_weekday = "tuesday"; }
        else if(#messageHasIntent("wednesday")) { set $desired_weekday = "wednesday"; }
        else if(#messageHasIntent("thursday")) { set $desired_weekday = "thursday"; }
        else if(#messageHasIntent("friday")) { set $desired_weekday = "friday"; }
        else if(#messageHasIntent("sunday")) { set $desired_weekday = "sunday"; }
        else if(#messageHasIntent("saturday")) { set $desired_weekday = "saturday"; }

        #sayText("Yes, we have a slot. You're all set. Anything else?");
        wait *;
    }
    transitions  {
        can_help: goto can_help on #messageHasSentiment("positive");
        confirm_appointment: goto confirm_appointment on #messageHasSentiment("negative");
    }
}

node can_help {
    do {
        #sayText("How can I help?");
        wait *;
    }
}

node confirm_appointment {
    do {
        #say("see_you_soon", { desired_weekday: $desired_weekday });
        #disconnect();
        exit;
     }
}

digression cancel_appt{
    conditions { on #messageHasIntent("cancel_appt"); }
    do {
        #sayText("You want to cancel your appointment, did I hear you correctly?");
        wait *;
    }
    transitions  {
        cancel_appt_do: goto cancel_appt_do on #messageHasSentiment("positive");
        confirm_appointment: goto confirm_appointment on #messageHasSentiment("negative");
    }
}

node cancel_appt_do {
    do {
        #sayText("Sorry to hear that. I cancelled your appointment. Care to reschedule?");
        wait *;
    }
    transitions  {
        schedule_haircut_day: goto schedule_haircut_day on #messageHasSentiment("positive");
        bye_bye: goto bye_bye on #messageHasSentiment("negative");
    }
}

node bye_bye {
    do {
        #sayText("No worries mate. Let us know when you're ready to get a cut in the hair and a spring in the step. Cheers!");
        #disconnect();
        exit;
    }
}

digression bye {
    conditions { on #messageHasIntent("bye"); }
    do {
        #sayText("Thanks for your call. Have a nice day. Bye!");
        #disconnect();
        exit;
    }
}