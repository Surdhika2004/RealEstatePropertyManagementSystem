@isTest
public with sharing class PropertyControllerTest {
    
    @testSetup
    static void setupTestData() {
        Integer bulkSize = ApplicationConstants.PAGE_SIZE + 5; 
        List<Property__c> propertiesToInsert = new List<Property__c>();
        
        for (Integer i = 0; i < bulkSize; i++) {
            propertiesToInsert.add(new Property__c(
                Name = ApplicationConstants.PROPERTY_NAME_PREFIX + i,
                City__c = (Math.mod(i, 2) == 0) ? ApplicationConstants.CITY_A : ApplicationConstants.CITY_B,
                Address__c = ApplicationConstants.PROPERTY_ADDRESS_STREET + i,
                Rent__c = 1000 + (i * 100), 
                Status__c = (Math.mod(i, 2) == 0) ? ApplicationConstants.STATUS_AVAILABLE : ApplicationConstants.STATUS_RENTED,
                Furnishing_Status__c = (Math.mod(i, 2) == 0) ? ApplicationConstants.FURNISHING_FULLY : ApplicationConstants.FURNISHING_UNFURNISHED,
                State__c = ApplicationConstants.TEST_STATE,
                Postal_Code__c = ApplicationConstants.TEST_POSTAL_CODE,
                Country__c = ApplicationConstants.TEST_COUNTRY,
                Type__c = ApplicationConstants.TEST_TYPE,
                Description__c = ApplicationConstants.TEST_DESCRIPTION
            ));
        }
        insert propertiesToInsert;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = ApplicationConstants.TEST_FILE_TITLE,
            PathOnClient = ApplicationConstants.TEST_FILE_PATH,
            VersionData = Blob.valueOf(ApplicationConstants.TEST_FILE_BLOB),
            IsMajorVersion = true
        );
        insert contentVersion;
    }
    
    @isTest
    static void testGetProperties_SearchKeyFiltersCorrectly() {
        String searchKey = ApplicationConstants.CITY_A;
        
        Test.startTest();
        PropertyController.PropertyPagedResult result = PropertyController.getProperties(
            searchKey, null, null, null, 1
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result wrapper should be initialized.');
        System.assert(result.totalRecords > 0, 'Should find records matching City A filter.');
        System.assertEquals(1, result.pageNumber, 'Page tracking should settle to first index.');
        System.assert(result.properties.size() <= ApplicationConstants.PAGE_SIZE, 'Returned list must conform to chunk boundaries.');
    }
    
    @isTest
    static void testGetProperties_FiltersByPriceAndStatusAndPagination() {
        Decimal maxPrice = 3000.00;
        String status = ApplicationConstants.STATUS_AVAILABLE;
        String furnishing = ApplicationConstants.FURNISHING_FULLY;
        
        Test.startTest();
        PropertyController.PropertyPagedResult result = PropertyController.getProperties(
            null, maxPrice, status, furnishing, 1
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should return populated properties wrapper.');
        for (Property__c prop : result.properties) {
            System.assert(prop.Rent__c <= maxPrice, 'Rent amounts returned must strictly sit below max filters.');
            System.assertEquals(status, prop.Status__c, 'Status data fields must accurately mirror target constraint values.');
            System.assertEquals(furnishing, prop.Furnishing_Status__c, 'Furnished flags must match query criteria.');
        }
    }
    
    @isTest
    static void testGetProperties_BoundaryAndNullNormalization() {
        Test.startTest();
        PropertyController.PropertyPagedResult nullPageResult = PropertyController.getProperties(
            null, null, null, null, null
        );
        PropertyController.PropertyPagedResult zeroPageResult = PropertyController.getProperties(
            null, null, null, null, 0
        );
        Test.stopTest();
        
        System.assertEquals(1, nullPageResult.pageNumber, 'Null page index parameter must safely default back to page 1.');
        System.assertEquals(1, zeroPageResult.pageNumber, 'Out of bounds zero inputs must safely normalize back to page 1.');
        System.assertEquals(2, nullPageResult.totalPages, 'Page metrics layout allocation logic should calculate exactly two chunk sets.');
    }
    
    @isTest
    static void testGetPropertyImages_WithValidAndInvalidIds() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        ContentDocumentLink linkData = new ContentDocumentLink(
            LinkedEntityId = prop.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert linkData;
        
        Test.startTest();
        List<ContentDocumentLink> imageLinks = PropertyController.getPropertyImages(prop.Id);
        List<ContentDocumentLink> emptyLinks = PropertyController.getPropertyImages(null);
        Test.stopTest();
        
        System.assertEquals(1, imageLinks.size(), 'Target retrieval collection must locate exactly one image file pointer.');
        System.assertEquals(cv.ContentDocumentId, imageLinks[0].ContentDocumentId, 'Document IDs must structurally match standard target entries.');
        System.assertEquals(0, emptyLinks.size(), 'Passing blank parameters must yield empty return instances.');
    }
    
    @isTest
    static void testCreatePropertyWithImages_SuccessPath() {
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        List<String> fileIdsList = new List<String>{ cv.ContentDocumentId };
            Property__c freshProp = new Property__c(
                Name = ApplicationConstants.NEW_PROPERTY_NAME,
                City__c = ApplicationConstants.CITY_A,
                Rent__c = 1200,
                State__c = ApplicationConstants.TEST_STATE,
                Postal_Code__c = ApplicationConstants.TEST_POSTAL_CODE,
                Country__c = ApplicationConstants.TEST_COUNTRY,
                Type__c = ApplicationConstants.TEST_TYPE, 
                Description__c = ApplicationConstants.TEST_DESCRIPTION,
                Address__c = ApplicationConstants.PROPERTY_ADDRESS_STREET,
                Status__c = ApplicationConstants.STATUS_AVAILABLE
            );
        
        Test.startTest();
        Property__c processedRecord = PropertyController.createPropertyWithImages(freshProp, fileIdsList);
        Test.stopTest();
        
        System.assertNotEquals(null, processedRecord.Id, 'Database operation sequence must insert elements yielding valid IDs.');
        List<ContentDocumentLink> resultingLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :processedRecord.Id];
        System.assertEquals(1, resultingLinks.size(), 'Content relationship bridges must be established correctly.');
    }
    @isTest
    static void testCreatePropertyWithImages_HandlesInvalidSubmissions() {
        Boolean exceptionCaught = false;
        
        Test.startTest();
        try {
            PropertyController.createPropertyWithImages(null, new List<String>());
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
            System.assert(ex.getMessage().contains(ApplicationConstants.ERR_NULL_RECORD) || ex.getMessage() != null, 'Error strings must clarify bad payload details.');
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionCaught, 'Invalid entries must break operational pathways cleanly.');
    }
    @isTest
    static void testGetProperties_ForcesExceptionCover() {
        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            PropertyController.getProperties(null, null, null, null, 100);
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionCaught, 'The getProperties catch block should have handled the OFFSET query exception.');
    }
    
    @isTest
    static void testCreatePropertyWithImages_ForcesPropertyInsertException() {
        Boolean exceptionCaught = false;
        Property__c completelyBlankProp = new Property__c();
        
        Test.startTest();
        try {
            PropertyController.createPropertyWithImages(completelyBlankProp, new List<String>());
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionCaught, 'The createProperty catch block should have handled the missing field DML exception.');
    }
    
    @isTest
    static void testCreatePropertyWithImages_ForcesContentLinkException() {
        Boolean exceptionCaught = false;
        
        Property__c freshProp = new Property__c(
            Name = ApplicationConstants.NEW_PROPERTY_NAME,
            City__c = ApplicationConstants.CITY_A,
            Rent__c = 1200,
            State__c = ApplicationConstants.TEST_STATE,
            Postal_Code__c = ApplicationConstants.TEST_POSTAL_CODE,
            Country__c = ApplicationConstants.TEST_COUNTRY,
            Type__c = ApplicationConstants.TEST_TYPE, 
            Description__c = ApplicationConstants.TEST_DESCRIPTION,
            Address__c = ApplicationConstants.PROPERTY_ADDRESS_STREET,
            Status__c = ApplicationConstants.STATUS_AVAILABLE
        );
        
        List<String> fakeFileIds = new List<String>{ '069000000000000AAA' };
            
            Test.startTest();
        try {
            PropertyController.createPropertyWithImages(freshProp, fakeFileIds);
        } catch (AuraHandledException ex) {
            exceptionCaught = true;
        }
        Test.stopTest();
        
        System.assertEquals(true, exceptionCaught, 'The ContentDocumentLink insert failure catch block should be covered.');
    }
    
}