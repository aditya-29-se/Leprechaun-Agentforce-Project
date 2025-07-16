import { LightningElement, api, wire, track } from 'lwc';
import getSpaRequestEligibilities from '@salesforce/apex/SpaRequestEligibilityGridController.getSpaRequestEligibilities';

const COLUMNS = [
    { label: 'Sap Agreement Number', fieldName: 'SapAgreementNumber__c' },
    { label: 'Direct Account', fieldName: 'DirectAccountName' },
    { label: 'Indirect Account', fieldName: 'IndirectAccountName' },
    { label: 'Indicator', fieldName: 'AEIndicator__c' },
    { label: 'Effective Date', fieldName: 'EligibilityEffectiveDate__c', type: 'date' },
    { label: 'Expire Date', fieldName: 'EligibilityExpireDate__c', type: 'date' }
];

export default class SpaRequestEligibilityGrid extends LightningElement {
    @api recordId;
    @track eligibilities = [];
    @track error;
    columns = COLUMNS;

    get isEmpty() {
        return Array.isArray(this.eligibilities) && this.eligibilities.length === 0;
    }

    @wire(getSpaRequestEligibilities, { parentId: '$recordId' })
    wiredEligibilities({ error, data }) {
        if (data) {
            // Map account Ids to Names for display
            this.eligibilities = data.map(row => ({
                ...row,
                DirectAccountName: row.DirectAccount__r ? row.DirectAccount__r.Name : '',
                IndirectAccountName: row.IndirectAccount__r ? row.IndirectAccount__r.Name : ''
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.eligibilities = [];
        }
    }
}