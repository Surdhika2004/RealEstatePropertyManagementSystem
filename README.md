# Real Estate Property Management System

## Overview

The **Real Estate Property Management System** is a Salesforce-based application developed to simplify the management of rental properties, tenants, lease agreements, maintenance requests, and vendors. The solution leverages standard Salesforce features along with custom objects, Apex, Lightning Web Components (LWC), and automation to provide an efficient property management experience.

---

## Features

- Property Management
- Tenant Management using Salesforce Person Accounts
- Vendor Management using Standard Account Record Types
- Lease Agreement Management
- Maintenance Request Tracking
- Property Dashboard (Lightning Web Component)
- Business Logic using Apex
- Trigger Framework for Maintenance Requests
- Validation Rules
- Custom Relationships

---

## Project Architecture

### Standard Objects

- Account (Person Account for Tenants)
- Account (Vendor Record Type)

### Custom Objects

- Property
- Lease Agreement
- Maintenance Request

---

## Data Model

### Property

Stores property details including:

- Property Name
- Address
- City
- State
- Country
- Postal Code
- Rent
- Furnishing Status
- Status
- Tenant (Lookup to Person Account)

### Tenant

Implemented using the **Salesforce Person Account** feature.

Contains:

- Name
- Email
- Phone
- Standard Account Information

### Vendor

Implemented using the **Standard Account** object with a dedicated **Vendor Record Type**.

Contains:

- Name
- Email
- Phone

### Lease Agreement

Stores rental agreement details including:

- Agreement Number
- Property
- Tenant
- Start Date
- End Date
- Agreed Monthly Rent
- Terms

### Maintenance Request

Tracks maintenance activities including:

- Maintenance Number
- Property
- Vendor
- Description
- Status

---

## Key Design Decisions

### Reuse of Standard Objects

Instead of creating separate custom objects for Tenant and Vendor, the standard **Account** object was reused.

- **Person Account** is used for Tenant records.
- **Vendor Record Type** is used for Vendor records.

This approach follows Salesforce best practices by minimizing unnecessary customizations and maximizing the use of standard platform functionality.

### Lookup Filter

The **Tenant** lookup field on the Property object is configured with a lookup filter to allow only **Person Account** records.

---

## Relationships

| Parent Object | Child Object | Relationship |
|--------------|-------------|--------------|
| Property | Lease Agreement | Master-Detail |
| Property | Maintenance Request | Lookup |
| Property | Tenant | Lookup (Person Account) |
| Maintenance Request | Vendor | Lookup (Account) |

---

## Apex Components

| Component | Coverage |
|-----------|---------:|
| ApplicationConstants | — |
| PropertyController | 97% |
| PropertyControllerTest | 97% |
| MaintenanceRequestTrigger | 100% |
| MaintenanceRequestTriggerHandler | 100% |
| MaintenanceRequestService | 80% |
| MaintenanceRequestServiceTest | — |

---

## Lightning Web Components

- Property Dashboard

---

## Technologies Used

- Salesforce Platform
- Apex
- Lightning Web Components (LWC)
- SOQL
- Salesforce CLI
- Visual Studio Code
- Git
- GitHub

---

## Project Structure

```
force-app/
└── main/
    └── default/
        ├── classes
        ├── lwc
        ├── objects
        ├── triggers
        ├── layouts
        ├── permissionsets
        └── applications