import { LightningElement, api, wire, track } from 'lwc';
import myImage from '@salesforce/resourceUrl/myImage';
import getRecordsComm from '@salesforce/apex/CommunicationStreamController.getRecordsComm';
import getPrimaryScenarioLineItems from '@salesforce/apex/PIScenarioLineItemController.getPrimaryScenarioLineItems';
import getAdhocApprovalHistory from '@salesforce/apex/Approval_HistoryController.getAdhocApprovalHistory';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import getScenariosForQuote from '@salesforce/apex/PIScenarioLineItemController.getScenariosForQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const commColumns = [
    { label: 'Note', fieldName: 'Note' },
    { label: 'Commented By', fieldName: 'CreatedByName' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
];

const scenarioLineColumns = [
    { label: 'LineNumber', fieldName: 'LineNumber' },
    { label: 'Unit List Price', fieldName: 'UnitListPrice', type: 'currency' },
    { label: 'Unit Book Price', fieldName: 'UnitBookPrice', type: 'currency' },
    { label: 'Authorized Price', fieldName: 'LineCurAuthorizedPrice', type: 'currency' }
];

const adhocApprovalColumns = [
    { label: 'Line Item Number', fieldName: 'Line_Item_Number__c' },
    { label: 'Product Name', fieldName: 'Product_Description__c' },
    { label: 'Quantity', fieldName: 'Quantity__c', type: 'number' },
    { label: 'PDCAT', fieldName: 'PDCAT__c' },
    { label: 'Unit List Price', fieldName: 'Unit_List_Price__c', type: 'currency' },
    { label: 'Status', fieldName: 'Ad_Hoc_Price_Status__c' },
];

export default class PriceManagerHomePage extends LightningElement {
    get isAdhocPending() {
        return this.adhocApprovalHistory?.some(record => record.Ad_Hoc_Price_Status__c === 'Pending');
    }
    channel = '/event/Price_Manager_Page_Events__e';
    isSubscribed = false;
    subscription = {};
    message;

    @track scenarioOptions = [];
    @track selectedScenarioId;
    @track scenarioOptionsError;
    wiredScenarioResult;


    imageUrl = myImage;
    @track quoteName = 'Sample Quote';
    @track accountName = 'Sample Account';
    @track status = 'Draft';
    @track scenario = { name: 'Scenario 1', description: 'Sample scenario for pricing' };
    @track scenarioLines = [
        { id: 1, name: 'Line 1', price: 100 },
        { id: 2, name: 'Line 2', price: 200 }
    ];

    @api recordId;
    dummyId='a0MgL0000009tYYUAY';
    @track communicationRecords = [];
    @track commError;
    commColumns = commColumns;
    wiredCommResult;

    @track scenarioLineItems = [];
    @track scenarioLineError;
    scenarioLineColumns = scenarioLineColumns;
    wiredScenarioLineResult;
    scenarioName;

    @track adhocApprovalHistory = [];
    @track adhocApprovalError;
    adhocApprovalColumns = adhocApprovalColumns;
    wiredAdhocApprovalHistoryResult;

    renderedCallback() {
        // This method is called when the component is rendered
        // You can perform any DOM manipulations or initializations here
        console.log('Component rendered with recordId:', this.recordId);
    }

    connectedCallback() {
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    @wire(getScenariosForQuote, { quoteId: '$recordId' })
    wiredScenarios(result) {
        this.wiredScenarioResult = result;
        const { error, data } = result;
        if (data) {
            this.scenarioOptions = data.map(s => ({ label: s.Name__c, value: s.Id }));
            this.scenarioOptionsError = undefined;
        } else if (error) {
            this.scenarioOptionsError = error;
            this.scenarioOptions = [];
        }
    }

    handleScenarioChange(event) {
        this.selectedScenarioId = event.detail.value;
        // You can add logic here to fetch scenario lines for the selected scenario if needed
    }

    @wire(getRecordsComm, { quoteId: '$recordId' })
    wiredRecords(result) {
        this.wiredCommResult = result;
        const { error, data } = result;
        console.log('recordId::::', this.wiredCommResult);
        if (data) {
            this.communicationRecords = data;
            this.commError = undefined;
        } else if (error) {
            this.commError = error;
            this.communicationRecords = [];
        }
    }

    @wire(getPrimaryScenarioLineItems, { quoteId: '$recordId' })
    wiredScenarioLines(result) {
        this.wiredScenarioLineResult = result;
        const { error, data } = result;
        if (data) {
            this.scenarioLineItems = data;
            this.scenarioLineError = undefined;
            this.scenarioName = data.length > 0 ? data[0].ParentScenarioName : '';
        } else if (error) {
            this.scenarioLineError = error;
            this.scenarioLineItems = [];
        }
    }

    @wire(getAdhocApprovalHistory, { quoteId: '$recordId' })
    wiredAdhocApprovalHistory(result) {
        this.wiredAdhocApprovalHistoryResult = result;
        const { error, data } = result;
        if (data) {
            this.adhocApprovalHistory = data;
            this.adhocApprovalError = undefined;
        } else if (error) {
            this.adhocApprovalError = error;
            this.adhocApprovalHistory = [];
        }
    }

    handleRefresh() {
        refreshApex(this.wiredCommResult);
    }

    handleSubscribe() {
        // Callback invoked when an event message is received
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            this.message = response.data.payload.Message__c;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Event Received',
                    message: 'Message: ' + this.message,
                    variant: 'success',
                }),
            );
            if(this.message === 'Scenario cloned successfully') {
                refreshApex(this.wiredScenarioLineResult);
                refreshApex(this.wiredScenarioResult);
            }
            if(this.message === 'Note Created') {
                refreshApex(this.wiredCommResult);
            }
            if(this.message === 'Adhoc Approval Histories Approved') {
                refreshApex(this.wiredAdhocApprovalHistoryResult);
            }
            if(this.message === 'Quote has been Authorized') {
                refreshApex(this.wiredCommResult);
            }
        };

        // Invoke subscribe()
        subscribe(this.channel, -1, messageCallback).then(response => {
            // Response is the subscription information
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
            this.isSubscribed = true;
        });
    }

    handleUnsubscribe() {
        if (this.isSubscribed) {
            // Invoke unsubscribe()
            unsubscribe(this.subscription, response => {
                console.log('unsubscribe() response: ', JSON.stringify(response));
                // Response is true for successful unsubscription
                this.isSubscribed = false;
            });
        }
    }
}