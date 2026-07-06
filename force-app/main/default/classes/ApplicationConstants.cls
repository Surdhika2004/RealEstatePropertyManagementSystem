public with sharing class ApplicationConstants {
   public static final Integer PAGE_SIZE = 25;
   //PropertyControllerTest.cls
   public static final String PROPERTY_NAME_PREFIX   = 'Test Property ';
    public static final String NEW_PROPERTY_NAME      = 'Brand New Villa';
    public static final String PROPERTY_ADDRESS_STREET = '123 Fake St ';
    public static final String CITY_A                  = 'Los Angeles';
    public static final String CITY_B                  = 'San Francisco';
    public static final String STATUS_AVAILABLE        = 'Available';
    public static final String STATUS_RENTED           = 'Occupied';
    public static final String TEST_STATE              = 'CA';
    public static final String TEST_POSTAL_CODE        = '90001';
    public static final String TEST_COUNTRY            = 'USA';
    public static final String TEST_TYPE               = 'Commercial'; 
    public static final String TEST_DESCRIPTION        = 'This is a beautiful test property description.';
    
    public static final String FURNISHING_FULLY        = 'Furnished'; 
    public static final String FURNISHING_UNFURNISHED  = 'Unfurnished';
    
    
    public static final String TEST_FILE_TITLE         = 'HouseImage';
    public static final String TEST_FILE_PATH          = 'HouseImage.jpg';
    public static final String TEST_FILE_BLOB          = 'Mock File Content Data';
    
    // Validation Error Message Assert Strings
    public static final String ERR_NULL_RECORD         = 'Property record cannot be null.';
    
    /**
     * Maintenance Request Status constants
     */
    public static final String OPEN = 'Open';
    public static final String IN_PROGRESS = 'In Progress';
    public static final String COMPLETED = 'Completed';
    public static final String CANCELLED = 'Cancelled';

    /**
     * Set of statuses considered active for workload calculation
     */
    public static final Set<String> ACTIVE_MAINTENANCE_STATUSES = new Set<String>{OPEN, IN_PROGRESS};

    /**
     * Error messages
     */
    public static final String ERR_NO_VENDOR_AVAILABLE = 'No Vendor available to assign the Maintenance Request.';

    /**
     * Future-proof constants for record types
     */
    public static final String VENDOR_RECORDTYPE = 'Vendor';
    public static final String VENDOR_RECORDTYPE_DEVELOPER_NAME = 'Vendor';
}