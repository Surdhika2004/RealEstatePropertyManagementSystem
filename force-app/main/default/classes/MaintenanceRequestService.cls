
/**
 * @description Service layer class for handling Maintenance Request calculations.
 * Refactored to utilize Account records as Vendors, using modern security practices and dynamic Record Types.
 */
public with sharing class MaintenanceRequestService {
    
    /**
     * @description Assigns the least loaded Vendor to each active incoming maintenance request record.
     * Bulk-safe. Restricts database operations to 2 SOQL statements total.
     * @param maintenanceRequests List of Maintenance_Request__c from a Before-Insert trigger context.
     */
    public static void assignVendor(List<Maintenance_Request__c> maintenanceRequests) {
        if (maintenanceRequests == null || maintenanceRequests.isEmpty()) {
            return;
        }

        // Fetch all active vendors (SOQL #1 - Respects Object/Field Access Levels via User Mode)
        List<Account> vendors = getAllVendors();

        // If no vendors exist, add errors across batch inputs to block transaction safely
        if (vendors.isEmpty()) {
            for (Maintenance_Request__c maintenanceRequest : maintenanceRequests) {
                maintenanceRequest.addError(ApplicationConstants.ERR_NO_VENDOR_AVAILABLE);
            }
            return;
        }

        // Extract vendor IDs and instantiate map metrics within a unified collection sweep
        Set<Id> vendorIds = new Set<Id>();
        Map<Id, Integer> workloadMap = new Map<Id, Integer>();
        for (Account vendor : vendors) {
            vendorIds.add(vendor.Id);
            workloadMap.put(vendor.Id, 0); 
        }

        // Overlay calculated workloads from database metrics (SOQL #2 - Aggregate)
        populateVendorWorkloads(vendorIds, workloadMap);

        // Assign vendors to each active maintenance request sequentially
        for (Maintenance_Request__c maintenanceRequest : maintenanceRequests) {
            // Skip tracking evaluation steps for dormant/closed status paths
            if (maintenanceRequest.Status__c == null || 
                !ApplicationConstants.ACTIVE_MAINTENANCE_STATUSES.contains(maintenanceRequest.Status__c)) {
                continue;
            }

            Id selectedVendorId = findLeastLoadedVendor(vendors, workloadMap);
            if (selectedVendorId == null) {
                maintenanceRequest.addError(ApplicationConstants.ERR_NO_VENDOR_AVAILABLE);
                continue;
            }

            maintenanceRequest.Vendor__c = selectedVendorId;

            // Increment workload locally to guarantee even load balancing across a bulk insert row array
            workloadMap.put(selectedVendorId, workloadMap.get(selectedVendorId) + 1);
        }
    }

    /**
     * @description Queries vendor accounts matching the configured Developer Name.
     * Deterministically sorted by Name to ensure predictable tie-breaking.
     * @return List of matching Account records.
     */
    private static List<Account> getAllVendors() {
        Id vendorRecordTypeId = getVendorRecordTypeId();
        if (vendorRecordTypeId == null) {
            return new List<Account>();
        }

        return [
            SELECT Id, Name
            FROM Account
            WHERE RecordTypeId = :vendorRecordTypeId
            WITH USER_MODE
            ORDER BY Name ASC
        ];
    }

    /**
     * @description Dynamically retrieves the Schema RecordType ID via its Developer Name.
     * @return The record type Id if found, otherwise null.
     */
    private static Id getVendorRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        if (recordTypeInfoMap == null || !recordTypeInfoMap.containsKey(ApplicationConstants.VENDOR_RECORDTYPE_DEVELOPER_NAME)) {
            return null;
        }
        return recordTypeInfoMap.get(ApplicationConstants.VENDOR_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
    }

    /**
     * @description Overlays workload counters dynamically using an optimization matrix.
     * @param vendorIds Set of active Vendor account IDs.
     * @param workloadMap Reference to the tracking map to be updated with aggregate values.
     */
    private static void populateVendorWorkloads(Set<Id> vendorIds, Map<Id, Integer> workloadMap) {
        if (vendorIds == null || vendorIds.isEmpty()) {
            return;
        }

        List<AggregateResult> aggregates = [
            SELECT Vendor__c vendorId, COUNT(Id) requestCount
            FROM Maintenance_Request__c
            WHERE Vendor__c IN :vendorIds
            AND Status__c IN :ApplicationConstants.ACTIVE_MAINTENANCE_STATUSES
            WITH USER_MODE
            GROUP BY Vendor__c
        ];

        for (AggregateResult ar : aggregates) {
            Id vendorId = (Id) ar.get('vendorId');
            Integer count = ((Decimal) ar.get('requestCount')).intValue();
            if (vendorId != null) {
                workloadMap.put(vendorId, count);
            }
        }
    }

    /**
     * @description Scans current vendor metrics to isolate the minimum workload count.
     * @param vendors Sorted List of potential Vendor accounts.
     * @param workloadMap Reference engine tracking workload assignments.
     * @return The target vendor Id, or null if unassigned.
     */
    private static Id findLeastLoadedVendor(List<Account> vendors, Map<Id, Integer> workloadMap) {
        if (vendors == null || vendors.isEmpty()) {
            return null;
        }

        Integer minimumWorkload = null;
        Id selectedVendorId = null;

        for (Account vendor : vendors) {
            Integer workload = workloadMap.containsKey(vendor.Id) ? workloadMap.get(vendor.Id) : 0;

            // First vendor acts as the initial baseline, or we find a lower workload
            if (minimumWorkload == null || workload < minimumWorkload) {
                minimumWorkload = workload;
                selectedVendorId = vendor.Id;
            }
        }

        return selectedVendorId;
    }
}

