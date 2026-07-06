
public with sharing class PropertyController {

    public class PropertyPagedResult {
        @AuraEnabled public List<Property__c> properties { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }

        public PropertyPagedResult() {
            properties = new List<Property__c>();
            totalRecords = 0;
            pageNumber = 1;
            totalPages = 0;
        }
    }

    @AuraEnabled(cacheable=false)
    public static PropertyPagedResult getProperties(
        String searchKey,
        Decimal maxPrice,
        String availabilityStatus,
        String furnishingStatus,
        Integer pageNumber
    ) {
        try {
            // Centralized constants configuration mapping
            Integer normalizedPageSize = ApplicationConstants.PAGE_SIZE;
            Integer normalizedPageNumber = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber;
            Integer offsetValue = (normalizedPageNumber - 1) * normalizedPageSize;

            // Streamlined input transformations via utility helper method
            String sanitizedSearchKey = sanitizeInput(searchKey);
            String escapedSearchKey = String.isBlank(sanitizedSearchKey) ? null : '%' + sanitizedSearchKey + '%';
            String escapedStatus = sanitizeInput(availabilityStatus);
            String escapedFurnishingStatus = sanitizeInput(furnishingStatus);

            List<String> whereClauses = new List<String>();
            
            if (String.isNotBlank(sanitizedSearchKey) && sanitizedSearchKey.length() >= 2) {
                whereClauses.add('(Name LIKE :escapedSearchKey OR City__c LIKE :escapedSearchKey OR Address__c LIKE :escapedSearchKey)');
            } else {
                if (maxPrice != null && maxPrice > 0) {
                    whereClauses.add('Rent__c <= :maxPrice');
                }
                if (String.isNotBlank(escapedStatus)) {
                    whereClauses.add('Status__c = :escapedStatus');
                }
                if (String.isNotBlank(escapedFurnishingStatus)) {
                    whereClauses.add('Furnishing_Status__c = :escapedFurnishingStatus');
                }
            }

            String whereClause = whereClauses.isEmpty() ? '' : ' WHERE ' + String.join(whereClauses, ' AND ');
            
            // Dynamic SOQL assembly without string-based security tokens
            String countQuery = 'SELECT COUNT() FROM Property__c' + whereClause;
            String dataQuery =
    'SELECT Id, Name, Address__c, City__c, State__c, Postal_Code__c, Country__c, ' +
    'Type__c, Furnishing_Status__c, Status__c, Rent__c, Description__c, ' +
    'Tenant__c, Tenant__r.Name ' +
    'FROM Property__c' +
    whereClause +
    ' ORDER BY Rent__c ASC LIMIT :normalizedPageSize OFFSET :offsetValue';

            // Enforce modern User Mode security on the dynamic database methods directly
            Integer totalRecords = Database.countQuery(countQuery, AccessLevel.USER_MODE);
            Integer totalPages = (totalRecords == 0) ? 1 : (Integer) Math.ceil((Decimal) totalRecords / normalizedPageSize);
            List<Property__c> properties = Database.query(dataQuery, AccessLevel.USER_MODE);

            PropertyPagedResult pagedResult = new PropertyPagedResult();
            pagedResult.properties = properties;
            pagedResult.totalRecords = totalRecords;
            pagedResult.pageNumber = normalizedPageNumber;
            pagedResult.totalPages = totalPages;
            return pagedResult;

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'PropertyController.getProperties failure: ' + ex.getMessage());
            throw new AuraHandledException('Unable to load properties. Please try again.');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getPropertyImages(Id propertyId) {
        if (propertyId == null) {
            return new List<ContentDocumentLink>();
        }

        try {
            return [SELECT ContentDocumentId 
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId = :propertyId 
                    WITH USER_MODE];
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'PropertyController.getPropertyImages failure: ' + ex.getMessage());
            throw new AuraHandledException('Unable to load property images.');
        }
    }

    @AuraEnabled(cacheable=false)
    public static Property__c createPropertyWithImages(Property__c propertyRecord, List<String> fileIds) {
        if (propertyRecord == null) {
            throw new AuraHandledException('Property record cannot be null.');
        }

        try {
            Database.insert(propertyRecord, AccessLevel.USER_MODE);
        } catch (DmlException ex) {
            System.debug(LoggingLevel.ERROR, 'PropertyController.createPropertyWithImages insert property failed: ' + ex.getMessage());
            throw new AuraHandledException('Unable to save the property. Please check your inputs and try again.');
        }

        if (fileIds != null && !fileIds.isEmpty()) {
            List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
            for (String fileId : fileIds) {
                if (String.isNotBlank(fileId)) {
                    contentLinks.add(new ContentDocumentLink(
                        ContentDocumentId = fileId,
                        LinkedEntityId = propertyRecord.Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                }
            }

            if (!contentLinks.isEmpty()) {
                try {
                    Database.insert(contentLinks, AccessLevel.USER_MODE);
                } catch (DmlException ex) {
                    System.debug(LoggingLevel.ERROR, 'PropertyController.createPropertyWithImages insert content links failed: ' + ex.getMessage());
                    throw new AuraHandledException('Property was created, but the uploaded images could not be attached. Please try again.');
                }
            }
        }

        return propertyRecord;
    }

    /**
     * Helper utility method to dry out input cleaning across search parameters
     */
    private static String sanitizeInput(String inputStr) {
        return String.isBlank(inputStr) ? null : String.escapeSingleQuotes(inputStr.trim());
    }
}

