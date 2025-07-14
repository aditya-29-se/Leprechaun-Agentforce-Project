import { LightningElement, wire, track } from 'lwc';
import getSubmitForAuthorizationQuotes from '@salesforce/apex/QuoteApprovalQueueController.getSubmitForAuthorizationQuotes';

const COLUMNS = [
    {
        label: 'Quote Number',
        fieldName: 'quoteLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'QuoteNumber' },
            target: '_blank'
        }
    },
    { label: 'Quote Name', fieldName: 'Name' },
    { label: 'Submitted Date', fieldName: 'SubmittedDate', type: 'date' },
    { label: 'Submitted By', fieldName: 'SubmittedByName' },
    { label: 'Authorizer', fieldName: 'AuthorizerName' }
];

export default class QuoteApprovalQueue extends LightningElement {
    @track quotes = [];
    @track error;
    columns = COLUMNS;

    get isEmpty() {
        return Array.isArray(this.quotes) && this.quotes.length === 0;
    }

    @wire(getSubmitForAuthorizationQuotes)
    wiredQuotes({ error, data }) {
        if (data) {
            // Link to standard Quote record detail page
            this.quotes = data.map(q => ({
                ...q,
                quoteLink: '/lightning/r/Quote__c/' + q.Id + '/view'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.quotes = [];
        }
    }
}