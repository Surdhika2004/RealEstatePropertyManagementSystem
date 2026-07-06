public with sharing class MaintenanceRequestTriggerHandler {
    /**
     * Handler for Maintenance Request trigger. No SOQL or DML here – just delegation.
     */
    public static void beforeInsert(List<Maintenance_Request__c> newMaintenanceRequests) {
        MaintenanceRequestService.assignVendor(newMaintenanceRequests);
    }
}
