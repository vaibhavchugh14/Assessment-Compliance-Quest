public class AccountTriggerHandler {
    public static void setActiveToFalse(List<Account> newAccList){
        for(Account acc : newAccList){
            if (acc.Active__c != false) {
                acc.Active__c = false;
            }
        }
    }
    
    public static void insertTeamMembers(List<Account> newAccList){
        List<SQX_Team_Members__c> teamMembersToInsert = new List<SQX_Team_Members__c>();
        
        for(Account acc : newAccList){ 
            for (Integer i = 1; i <= 2; i++) {
                SQX_Team_Members__c teamMember = new SQX_Team_Members__c();
                teamMember.Name = 'Team Member ' + i;
                teamMember.Contact_Info__c = null;
                teamMember.Member_Type__c = null;
                teamMember.Account__c = acc.Id;
                teamMembersToInsert.add(teamMember);
            }
        }
        
        if(!teamMembersToInsert.isEmpty()){
            insert teamMembersToInsert;
        }
    }

    public static void activateAccount(List<Account> newAccList, Map<Id, Account> oldAccMap){
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newAccList) {
            Account oldAcc = oldAccMap.get(acc.Id);
            if (acc.Active__c && !oldAcc.Active__c) {
                accountIds.add(acc.Id);
            }
        }

        if (!accountIds.isEmpty()) {
            Boolean hasPermission = hasAccountAdminPermission();
            if (!hasPermission){
                for (Account acc : newAccList){
                    if(accountIds.contains(acc.Id)){
                        acc.addError('You do not have permission to activate accounts.');
                    }
                }
                return;
            }

            Map<Id, Set<String>> teamMemberTypes = new Map<Id, Set<String>>();
            for (SQX_Team_Members__c teamMember : [select Account__c, Member_Type__c FROM SQX_Team_Members__c where Account__c IN :accountIds]) {
                if (!teamMemberTypes.containsKey(teamMember.Account__c)) {
                    teamMemberTypes.put(teamMember.Account__c, new Set<String>());
                }
                teamMemberTypes.get(teamMember.Account__c).add(teamMember.Member_Type__c);
            }
            
            for (Account acc : newAccList) {
                if (acc.Active__c && oldAccMap.get(acc.Id).Active__c == false){
                    Set<String> memberTypes = teamMemberTypes.get(acc.Id);
                    if (memberTypes == null || !memberTypes.contains('HR') || !memberTypes.contains('Admin')){
                        acc.addError('Account cannot be activated without both HR and Admin team members.');
                    }
                }
            }
        }
    }

    private static Boolean hasAccountAdminPermission() {
        return [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSet.Name = 'Account_Admin' LIMIT 1].size() > 0;
    }
}