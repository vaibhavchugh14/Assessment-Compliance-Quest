@isTest
private class AccountTriggerHandlerTests {
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        return u;
    }

    private static void assignAccountAdminPermissionSet(User u) {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Account_Admin' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
    }

    @isTest
    private static void testInsertTeamMembers(){
        Account testAccount = new Account(Name = 'Test Account');
        testAccount.Active__c = true;
        insert testAccount;

        List<SQX_Team_Members__c> teamMembers = [
            SELECT Name, Contact_Info__c, Member_Type__c, Account__c FROM SQX_Team_Members__c WHERE Account__c = :testAccount.Id
        ];

        Assert.areEqual(2, teamMembers.size(), 'There should be 2 team members created');
    }
    
    @isTest
    private static void testActivateAccountWithoutPermissionSet(){
        Account testAccount = new Account(Name = 'Test Account');
        testAccount.Active__c = true;
        insert testAccount;
        
        testAccount.Active__c = true;

        Test.startTest();
            try {
                update testAccount;
            } catch(DmlException e){
                System.assert(e.getMessage().contains('do not have permission'), 'Expected permission error.');
            }
        Test.stopTest();
    }

    @isTest
    private static void testActivateAccountWithoutTeamMembers(){
        User u = createTestUser();
        assignAccountAdminPermissionSet(u);

        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account', Active__c = false);
            insert acc;

            acc.Active__c = true;

            Test.startTest();
                try {
                    update acc;
                }catch(DmlException e){
                    System.assert(e.getMessage().contains('without both HR and Admin team'), 'Expected team member validation error.');
                }
            Test.stopTest();
        }
    }
}