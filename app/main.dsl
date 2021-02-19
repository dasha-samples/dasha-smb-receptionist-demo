import "commonReactions/all.dsl";
import "confirmIntent.dsl";

context {
    input phone: string;
    desired_weekday: string = "";
}

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

global digression schedule_haircut
{
    conditions {on #messageHasIntent("schedule_haircut");}
    do
    {
        var confirmed = blockcall confirmIntent("Do you want to schedule a haircut?", "schedule_haircut", 1, $du_text);
        if (confirmed) {
            #sayText("Okay. What day would you like to come in?");
        }
        wait *;
    }
}

global digression cancel_appt
{
    conditions {on #messageHasIntent("cancel_appt");}
    do
    {
        var confirmed = blockcall confirmIntent("Do you want to cancel your appointment?", "cancel_appt", 1, $du_text);
        if (confirmed) {
            #sayText("Sorry to hear that. I cancelled your appointment.");
        }
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