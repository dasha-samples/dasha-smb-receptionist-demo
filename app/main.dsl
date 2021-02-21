import "commonReactions/all.dsl";
import "confirmIntent.dsl";

context {
    input phone: string;
    desired_weekday: string = "";
}

external function updateIntents(intent: string, text: string?, confirmed: boolean): unknown;

start node root
{
    do
    {
        #connectSafe($phone);
        #waitForSpeech(1000);
        #sayText("Church Barber and Apothecary! How can I help you?");
        wait *;
    }
}

digression schedule_haircut
{
    conditions {on #messageHasIntent("schedule_haircut");}
    do
    {
        var await_confirmation = blockcall confirmIntent("Umm...Do you want to schedule a haircut?", "schedule_haircut", 0.5, $du_text);
        if (await_confirmation) {
            wait *;
        } else {
            goto @do;
        }
    }
    transitions {
        @do: goto schedule_haircut_do;
        confirmed: goto schedule_haircut_do on digression.confirm_intent.shared.confirmed priority 50;
    }
}

node schedule_haircut_do {
    do {
        #sayText("Okay. What day would you like to come in?");
        wait *;
    }
}

digression cancel_appt
{
    conditions {on #messageHasIntent("cancel_appt");}
    do
    {
        var await_confirmation = blockcall confirmIntent("Do you want to cancel your appointment?", "cancel_appt", 1, $du_text);
        if (await_confirmation) {
            wait *;
        } else {
            goto @do;
        }
    }
    transitions {
        @do: goto cancel_appt_do;
        confirmed: goto cancel_appt_do on digression.confirm_intent.shared.confirmed priority 50;
    }
}

node cancel_appt_do {
    do {
        #sayText("Sorry to hear that. I cancelled your appointment.");
        wait *;
    }
}

digression weekday
{
    conditions { on #messageHasAnyIntent(["monday", "tuesday", "wednesday", "thursday", "friday", "sunday", "saturday"]); }
    do{
        #sayText("Let me just check the books...");

        if(#messageHasIntent("monday")) { set $desired_weekday = "monday";}
        else if(#messageHasIntent("tuesday")) { set $desired_weekday = "tuesday";}
        else if(#messageHasIntent("wednesday")) { set $desired_weekday = "wednesday";}
        else if(#messageHasIntent("thursday")) { set $desired_weekday = "thursday";}
        else if(#messageHasIntent("friday")) { set $desired_weekday = "friday";}
        else if(#messageHasIntent("sunday")) { set $desired_weekday = "sunday";}
        else if(#messageHasIntent("saturday")) { set $desired_weekday = "saturday";}

        #log($desired_weekday);
        #sayText("Yes, we have a slot. You're all set.");
        wait *;
    }
}

digression bye
{
    conditions { on #messageHasIntent("bye"); }
    do
    {
        #sayText("Have a nice day. Bye!");
    }
}