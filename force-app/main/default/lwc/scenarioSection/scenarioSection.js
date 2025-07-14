import { LightningElement, api,wire,track } from 'lwc';
import getScenariosForQuote from '@salesforce/apex/PIScenarioLineItemController.getScenariosForQuote';

export default class ScenarioSection extends LightningElement {
    @api scenarioName;
    @api scenarioOptions = [];
    @track selectedScenarioId;
    @track scenarioOptionsError;
    @api recordId;

    handleScenarioChange(event) {
        this.selectedScenarioId = event.detail.value;
        // You can add logic here to fetch scenario lines for the selected scenario if needed
    }
}