@isTest
private class MaintenanceRequestServiceTest {

    @testSetup
    static void setupTestData() {
        // 1. Dynamically retrieve the Vendor Record Type ID using your constant string
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Id vendorRtId = rtMap.get(ApplicationConstants.VENDOR_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();

        // 2. Create Vendor Accounts (Deterministic naming for tie-breaking)
        List<Account> vendorsToInsert = new List<Account>();
        vendorsToInsert.add(new Account(Name = 'Vendor A', RecordTypeId = vendorRtId));
        vendorsToInsert.add(new Account(Name = 'Vendor B', RecordTypeId = vendorRtId));
        insert vendorsToInsert;
    }

    @isTest
    static void testAssignVendor_SuccessfulFairDistribution() {
        // Extract vendors built in test setup
        List<Account> vendors = [SELECT Id FROM Account ORDER BY Name ASC];
        
        // Grab an active status dynamically from your global architecture constants
        List<String> activeStatuses = new List<List<String>>{new List<String>(ApplicationConstants.ACTIVE_MAINTENANCE_STATUSES)}[0];
        String targetActiveStatus = activeStatuses[0];

        // Prepare 3 test requests to check our local round-robin iteration engine
        List<Maintenance_Request__c> requests = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < 3; i++) {
            requests.add(new Maintenance_Request__c(
                Status__c = targetActiveStatus
            ));
        }

        Test.startTest();
        // Execute the service in a before-insert trigger simulation layer
        MaintenanceRequestService.assignVendor(requests);
        Test.stopTest();

        // Vendor A should take the first because of alphabetical sorting (tie-breaker)
        Assert.areEqual(vendors[0].Id, requests[0].Vendor__c, 'First active task should fall to Vendor A.');
        // Vendor B should take the second row assignment to achieve perfect load balancing
        Assert.areEqual(vendors[1].Id, requests[1].Vendor__c, 'Second active task should balance out to Vendor B.');
        // Vendor A should receive the third assignment row loop pass
        Assert.areEqual(vendors[0].Id, requests[2].Vendor__c, 'Third active task should loop back round to Vendor A.');
    }

    @isTest
    static void testAssignVendor_SkipsNonActiveStatusRecords() {
        List<Maintenance_Request__c> requests = new List<Maintenance_Request__c>();
        
        // Intentionally assigning a status not present inside the global configuration set
        requests.add(new Maintenance_Request__c(
            Status__c = 'Completed' 
        ));

        Test.startTest();
        MaintenanceRequestService.assignVendor(requests);
        Test.stopTest();

        Assert.isNull(requests[0].Vendor__c, 'Dormant or closed status pathways must bypass the assignment logic entirely.');
    }

    @isTest
    static void testAssignVendor_BulkScaleLoadValidation() {
        List<String> activeStatuses = new List<List<String>>{new List<String>(ApplicationConstants.ACTIVE_MAINTENANCE_STATUSES)}[0];
        String targetActiveStatus = activeStatuses[0];

        // Build a complete 200 record block row to guarantee governor safety boundaries hold up
        List<Maintenance_Request__c> bulkRequests = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkRequests.add(new Maintenance_Request__c(
                Status__c = targetActiveStatus
            ));
        }

        Test.startTest();
        MaintenanceRequestService.assignVendor(bulkRequests);
        Test.stopTest();

        // Ensure every single record received a valid pointer mapping assignment
        for (Maintenance_Request__c req : bulkRequests) {
            Assert.isNotNull(req.Vendor__c, 'Every record in a massive bulk run must match a valid assignment route.');
        }
    }

    @isTest
    static void testAssignVendor_NoVendorsThrowsException() {
        // Clean out database states completely to test empty catch behaviors safely
        delete [SELECT Id FROM Account];

        List<String> activeStatuses = new List<List<String>>{new List<String>(ApplicationConstants.ACTIVE_MAINTENANCE_STATUSES)}[0];
        Maintenance_Request__c failedRequest = new Maintenance_Request__c(Status__c = activeStatuses[0]);

        Boolean exceptionCaught = false;

        Test.startTest();
        try {
            // Inserting a record through DML trips the addError rollback rule inside our trigger handler
            insert failedRequest;
        } catch (DmlException ex) {
            exceptionCaught = true;
            // Validate that the custom exception match criteria maps cleanly to corporate constants
            Assert.isTrue(ex.getMessage().contains(ApplicationConstants.ERR_NO_VENDOR_AVAILABLE), 
                'The transactional error message text strings must mirror validation layer setups.');
        }
        Test.stopTest();

        Assert.isTrue(exceptionCaught, 'The validation filter rule must catch empty vendor footprints and throw.');
    }
}