import { LightningElement, api, wire } from 'lwc';
import getAgreementLinesByAgreementId from '@salesforce/apex/SapVistexAgreementLineController.getAgreementLinesByAgreementId';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Agreement Number', fieldName: 'SAP_Agreement_Number__c' },
    { label: 'Item Code', fieldName: 'Item_Code__c' },
    { label: 'Unit List Price', fieldName: 'Unit_List_Price__c', type: 'currency' }
    // Add more columns as needed
];

export default class SapVistexAgreementLineList extends LightningElement {
    @api recordId;
    lines;
    error;
    columns = COLUMNS;

    get isEmpty() {
        return Array.isArray(this.lines) && this.lines.length === 0;
    }

    @wire(getAgreementLinesByAgreementId, { recordId: '$recordId' })
    wiredLines({ error, data }) {
        if (data) {
            this.lines = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.lines = undefined;
        }
    }
}