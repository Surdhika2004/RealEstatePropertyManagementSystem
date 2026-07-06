import { LightningElement } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProperties from '@salesforce/apex/PropertyController.getProperties';
import getPropertyImages from '@salesforce/apex/PropertyController.getPropertyImages';
import createPropertyWithImages from '@salesforce/apex/PropertyController.createPropertyWithImages';
import MALLOW_LOGO from '@salesforce/resourceUrl/MallowLogo';

const PAGE_SIZE = 25;
const DEFAULT_MAX_PRICE = 50000;
const DEFAULT_FILTERS = Object.freeze({
    maxPrice: DEFAULT_MAX_PRICE,
    status: '',
    furnishingStatus: ''
});

export default class PropertyDashboard extends LightningElement {
    mallowLogoUrl = MALLOW_LOGO;

    properties = [];
    pageNumber = 1;
    totalPages = 1;
    totalRecords = 0;

    searchKey = '';
    isFilterMenuOpen = false;
    isLoading = true;

    draftFilters = { ...DEFAULT_FILTERS };
    appliedFilters = { ...DEFAULT_FILTERS };

    isModalOpen = false;
    uploadedFileIds = [];
    uploadedFiles = [];
    propertyName = null;
    propertyAddress = null;
    propertyCity = null;
    propertyState = null;
    propertyPostalCode = null;
    propertyCountry = null;
    propertyType = null;
    propertyFurnishingStatus = null;
    propertyStatus = null;
    propertyRent = null;
    propertyDescription = null;
    selectedPropertyId = null;
    attachedImageIds = [];
    propertyRecordId = null;
    isEditMode = false;

    columns = [
        {
            label: 'S.No',
            fieldName: 'serialNumber',
            type: 'text'
        },
        {
            label: 'Name',
            fieldName: 'Name',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'Name' },
                name: 'view_details',
                variant: 'base',
                class: 'slds-text-link_reset'
            }
        },
        { label: 'Address', fieldName: 'Address__c' },
        { label: 'City', fieldName: 'City__c' },
        { label: 'Type', fieldName: 'Type__c' },
        { label: 'Status', fieldName: 'Status__c' },

{
    label: 'Tenant',
    fieldName: 'tenantName',
    type: 'text'
},

{ label: 'Furnishing Status', fieldName: 'Furnishing_Status__c' },

{ label: 'Rent', fieldName: 'Rent__c', type: 'currency' }
    ];

    get typeOptions() {
        return [
            { label: 'Residential', value: 'Residential' },
            { label: 'Commercial', value: 'Commercial' }
        ];
    }

    get statusOptions() {
        return [
            { label: 'Available', value: 'Available' },
            { label: 'Occupied', value: 'Occupied' }
        ];
    }

    get furnishingOptions() {
        return [
            { label: 'Furnished', value: 'Furnished' },
            { label: 'Semi-Furnished', value: 'Semi-Furnished' },
            { label: 'Unfurnished', value: 'Unfurnished' }
        ];
    }

    connectedCallback() {
        this.loadProperties();
    }

    get hasRecords() {
        return this.properties.length > 0;
    }

    get isPreviousDisabled() {
        return this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.pageNumber >= this.totalPages;
    }

    get pageNumberObjects() {
        const total = this.totalPages || 1;
        return Array.from({ length: total }, (_, index) => {
            const num = index + 1;
            return {
                num,
                className: num === this.pageNumber ? 'pill current' : 'pill',
                label: `Page ${num}`
            };
        });
    }

    get showingStart() {
        return this.totalRecords === 0 ? 0 : ((this.pageNumber - 1) * PAGE_SIZE) + 1;
    }

    get showingEnd() {
        return this.totalRecords === 0 ? 0 : Math.min(this.pageNumber * PAGE_SIZE, this.totalRecords);
    }

    get showNoRecords() {
        return !this.isLoading && !this.hasRecords;
    }

    get hasUploadedFiles() {
        return this.uploadedFiles.length > 0;
    }

    get uploadedFilesCount() {
        return this.uploadedFiles.length;
    }

    get hasActiveFilters() {
        const hasTextSearch = this.searchKey.trim().length >= 2;
        const hasAdvancedFilters = this.appliedFilters.maxPrice !== DEFAULT_MAX_PRICE
            || Boolean(this.appliedFilters.status)
            || Boolean(this.appliedFilters.furnishingStatus);
        return hasTextSearch || hasAdvancedFilters;
    }

    handleStatusChange(event) {
        this.draftFilters = {
            ...this.draftFilters,
            status: event.detail?.value ?? ''
        };
    }

    handleFurnishingStatusChange(event) {
        this.draftFilters = {
            ...this.draftFilters,
            furnishingStatus: event.detail?.value ?? ''
        };
    }

    toggleFilterMenu() {
        this.isFilterMenuOpen = !this.isFilterMenuOpen;
    }

    handleApplyFilters() {
        this.appliedFilters = { ...this.draftFilters };
        this.searchKey = '';
        this.pageNumber = 1;
        this.loadProperties();
        this.isFilterMenuOpen = false;
    }

    handleResetFilters() {
        this.searchKey = '';
        this.draftFilters = { ...DEFAULT_FILTERS };
        this.appliedFilters = { ...DEFAULT_FILTERS };
        this.pageNumber = 1;
        this.isFilterMenuOpen = false;
        this.loadProperties();
    }

    handleSearchKeyChange(event) {
        const value = (event.target?.value ?? '').trim();
        if (value === this.searchKey) {
            return;
        }

        this.searchKey = value;

        if (value.length === 0) {
            this.pageNumber = 1;
            this.loadProperties();
            return;
        }

        if (value.length >= 2) {
            this.pageNumber = 1;
            this.loadProperties();
        }
    }

    handleSliderChange(event) {
        this.draftFilters = {
            ...this.draftFilters,
            maxPrice: Number(event.detail?.value ?? event.target?.value ?? DEFAULT_MAX_PRICE)
        };
    }

    handleRowClick(event) {
    const row = event.detail?.row;
    if (row?.Id) {
        this.selectedPropertyId = row.Id;
        this.attachedImageIds = [];
        this.isEditMode = false;
        this.loadPropertyImages(this.selectedPropertyId);
    }
}
    closeDetailModal() {
    this.selectedPropertyId = null;
    this.attachedImageIds = [];
    this.isEditMode = false;
}handleEdit() {
    this.isEditMode = true;
}

handleCancelEdit() {
    this.isEditMode = false;
}

handlePropertyUpdateSuccess() {
    this.isEditMode = false;

    this.showToast(
        'Success',
        'Property updated successfully.',
        'success'
    );

    this.loadProperties();
}

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
            this.loadProperties();
        }
    }

    goToPage(event) {
        const page = Number(event.currentTarget.dataset.page);
        if (!page || page === this.pageNumber) {
            return;
        }
        this.pageNumber = page;
        this.loadProperties();
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
            this.loadProperties();
        }
    }

    handleNewPropertyClick() {
        this.openModal();
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetModalFields();
        this.selectedPropertyId = null;
        this.attachedImageIds = [];
    }

    handleFieldChange(event) {
        const fieldName = event.target?.dataset?.id;
        if (!fieldName) {
            return;
        }

        const fieldMap = {
            Name: 'propertyName',
            Address__c: 'propertyAddress',
            City__c: 'propertyCity',
            State__c: 'propertyState',
            Postal_Code__c: 'propertyPostalCode',
            Country__c: 'propertyCountry',
            Type__c: 'propertyType',
            Furnishing_Status__c: 'propertyFurnishingStatus',
            Status__c: 'propertyStatus',
            Rent__c: 'propertyRent',
            Description__c: 'propertyDescription'
        };

        const targetProp = fieldMap[fieldName] || fieldName;
        this[targetProp] = event.detail?.value ?? event.target?.value ?? null;
    }

    handleUploadFinished(event) {
        const uploaded = (event.detail?.files ?? []).map(file => ({ id: file.documentId, name: file.name }));
        this.uploadedFiles = [...this.uploadedFiles, ...uploaded];
        this.uploadedFileIds = this.uploadedFiles.map(file => file.id);
    }

    handleRemoveImage(event) {
        const fileId = event.target?.dataset?.id;
        if (!fileId) {
            return;
        }

        deleteRecord(fileId)
            .then(() => {
                this.uploadedFiles = this.uploadedFiles.filter(file => file.id !== fileId);
                this.uploadedFileIds = this.uploadedFiles.map(file => file.id);
                this.showToast('Image removed', 'The image was removed successfully.', 'success');
            })
            .catch(error => {
                console.error('Error removing image', error);
                this.showToast('Remove Failed', 'Unable to remove the image. Please try again.', 'error');
            });
    }

    handleSaveProperty() {
        const formFields = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
        const propertyRecord = {};
        let allValid = true;

        formFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                allValid = false;
            }

            const apiName = field.dataset.id;
            if (apiName) {
                propertyRecord[apiName] = field.value;
            }
        });

        if (!allValid) {
            return;
        }

        if (!this.uploadedFiles.length) {
            this.showToast('Validation Error', 'An image upload is mandatory. Please attach a property photo to complete the creation.', 'error');
            return;
        }

        const fileIds = this.uploadedFiles.map(file => file.id);

        createPropertyWithImages({ propertyRecord, fileIds })
            .then(() => {
                this.showToast('Success', 'Property created successfully.', 'success');
                this.closeModal();
                this.loadProperties();
            })
            .catch(error => {
                this.showToast('Error creating property', this.extractErrorMessage(error), 'error');
            });
    }

    extractErrorMessage(error) {
        if (!error) {
            return 'An unknown error occurred.';
        }

        if (error.body) {
            if (Array.isArray(error.body)) {
                return error.body.map(err => err.message).join('; ');
            }
            return error.body.message || JSON.stringify(error.body);
        }

        return error.message || JSON.stringify(error);
    }

    loadPropertyImages(propertyId) {
        getPropertyImages({ propertyId })
            .then(result => {
                this.attachedImageIds = (result || []).map(file => `/sfc/servlet.shepherd/document/download/${file.ContentDocumentId}`);
            })
            .catch(error => {
                console.error('Error fetching images:', error);
                this.attachedImageIds = [];
            });
    }

    loadProperties() {
        this.isLoading = true;
        getProperties({
            searchKey: this.searchKey,
            maxPrice: this.appliedFilters.maxPrice,
            availabilityStatus: this.appliedFilters.status,
            furnishingStatus: this.appliedFilters.furnishingStatus,
            pageNumber: this.pageNumber
        })
            .then(result => {
               this.properties = (result?.properties || []).map((prop, index) => ({
    ...prop,
    serialNumber: ((this.pageNumber - 1) * PAGE_SIZE) + index + 1,
    tenantName: prop.Tenant__r ? prop.Tenant__r.Name : ''
}));
                this.totalRecords = result?.totalRecords ?? 0;
                this.totalPages = result?.totalPages ? Math.max(1, result.totalPages) : 1;
                this.pageNumber = result?.pageNumber ?? this.pageNumber;
                this.isLoading = false;
            })
            .catch(error => {
                this.properties = [];
                this.totalRecords = 0;
                this.totalPages = 1;
                this.pageNumber = 1;
                this.isLoading = false;
                this.showToast('Error loading properties', error.body?.message || error.message || 'Unable to load properties.', 'error');
            });
    }

    resetModalFields() {
        this.propertyName = null;
        this.propertyAddress = null;
        this.propertyCity = null;
        this.propertyState = null;
        this.propertyPostalCode = null;
        this.propertyCountry = null;
        this.propertyType = null;
        this.propertyFurnishingStatus = null;
        this.propertyStatus = null;
        this.propertyRent = null;
        this.propertyDescription = null;
        this.uploadedFileIds = [];
        this.uploadedFiles = [];
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
