import { LightningElement, api, wire, track } from 'lwc';
import getSpaRequestLineItems from '@salesforce/apex/SpaRequestLineItemsGridController.getSpaRequestLineItems';

const COLUMNS = [
    { label: 'Item Code', fieldName: 'Item_Code__c' },
    { label: 'Item Description', fieldName: 'Item_Description__c' },
    { label: 'Unit Book Price', fieldName: 'Unit_Book_Price__c', type: 'currency' },
    { label: 'Unit Profile Price', fieldName: 'Unit_Profile_Price__c', type: 'currency' },
    { label: 'Profile Multiplier', fieldName: 'ProfileMultiplier__c', type: 'number' },
    { label: 'Requested Net Multiplier Rebate', fieldName: 'Requested_Net_Multiplier_Rebate__c', type: 'number' },
    { label: 'AME Indicator', fieldName: 'AME_Indicator__c' },
    { label: 'Requested Net Price Rebate', fieldName: 'Requested_Net_Price_Rebate__c', type: 'currency' }
];

export default class SpaRequestLineItemsGrid extends LightningElement {
    @api recordId;
    @track lineItems = [];
    @track error;
    columns = COLUMNS;

    get isEmpty() {
        return Array.isArray(this.lineItems) && this.lineItems.length === 0;
    }

    @wire(getSpaRequestLineItems, { parentId: '$recordId' })
    wiredLineItems({ error, data }) {
        if (data) {
            this.lineItems = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.lineItems = [];
        }
    }
}