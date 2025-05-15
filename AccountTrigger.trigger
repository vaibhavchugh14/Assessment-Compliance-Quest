trigger AccountTrigger on Account(before insert, after insert, before update){
    if(Trigger.isBefore && Trigger.isInsert){
        AccountTriggerHandler.setActiveToFalse(Trigger.new);
    }
    else if(Trigger.isAfter && Trigger.isInsert){
        AccountTriggerHandler.insertTeamMembers(Trigger.new);
    }
    else if(Trigger.isBefore && Trigger.isUpdate){
        AccountTriggerHandler.activateAccount(Trigger.new, Trigger.oldMap);
    }
}