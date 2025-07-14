import { LightningElement, api } from 'lwc';

const COLUMNS = [
    { label: 'Line Name', fieldName: 'name' },
    { label: 'Price', fieldName: 'price', type: 'currency' }
];

export default class ScenarioLines extends LightningElement {
    @api lines;
    columns = COLUMNS;
}