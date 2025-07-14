public with sharing class PIScenarioLineItemController {
    public class ScenarioLineItemWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String ParentScenarioName;
        @AuraEnabled public Decimal UnitListPrice;
        @AuraEnabled public Decimal UnitBookPrice;
        @AuraEnabled public Decimal LineCurAuthorizedPrice;
        @AuraEnabled public String LineNumber;
        @AuraEnabled public Id ParentScenarioId;
        public ScenarioLineItemWrapper(PI_Scenario_Line_Item__c item) {
            Id = item.Id;
            ParentScenarioName = item.Parent_Scenario__r != null ? item.Parent_Scenario__r.Name__c : null;
            UnitListPrice = item.Unit_List_Price__c;
            UnitBookPrice = item.Unit_Book_Price__c;
            LineCurAuthorizedPrice = item.Line_cur_AuthorizedPrice__c;
            LineNumber = item.Line_Number__c;
            ParentScenarioId = item.Parent_Scenario__c;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ScenarioLineItemWrapper> getPrimaryScenarioLineItems(Id quoteId) {
        List<PI_Scenario_Line_Item__c> items = [
            SELECT Id, Parent_Scenario__r.Name__c, Unit_List_Price__c, Unit_Book_Price__c, Line_cur_AuthorizedPrice__c, Line_Number__c, Parent_Scenario__c
            FROM PI_Scenario_Line_Item__c
            WHERE Parent_Scenario__r.Quote__c = :quoteId
              AND Parent_Scenario__r.isPrimary__c = true
        ];
        List<ScenarioLineItemWrapper> wrappers = new List<ScenarioLineItemWrapper>();
        for (PI_Scenario_Line_Item__c item : items) {
            wrappers.add(new ScenarioLineItemWrapper(item));
        }
        return wrappers;
    }

    @AuraEnabled(cacheable=true)
    public static List<PI_Scenario__c> getScenariosForQuote(Id quoteId) {
        Quote__c q= [
            SELECT Id, SPD_Rev_Number__c
            FROM Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];
        return [
            SELECT Id, Name__c
            FROM PI_Scenario__c
            WHERE Quote__c = :quoteId and Quote_Rev__c = :q.SPD_Rev_Number__c 
            ORDER BY Name__c
        ];
    }

    @InvocableMethod(label='Clone Scenario' description='This method does something useful.')
    public static List<Id> cloneScenario(List<AccountSummaryRequestForLine> requests) {
        return cloneScenarioWithLineItems(
            requests[0].baseScenarioName,
            requests[0].newScenarioName
        );
    }

    public class AccountSummaryRequestForLine {
        @InvocableVariable(label='baseScenarioName' description='The name of existing base scenario' required=true)
        public String baseScenarioName;
        @InvocableVariable(label='newScenarioName' description='The name of new scenario' required=true)
        public String newScenarioName;
    }

    public static List<Id> cloneScenarioWithLineItems(String baseScenarioName, String newScenarioName) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sobject_type = globalDescribe.get('PI_Scenario__c');
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<String> fields = new List<String>(field_map.keySet());
        String soql = 'SELECT ' + String.join(fields, ',') + ' FROM PI_Scenario__c WHERE Name__c = :baseScenarioName LIMIT 1';
        PI_Scenario__c originalScenario = Database.query(soql);

        List<pi_scenario__c> previousScenarios = [
            SELECT Id, isPrimary__c
            FROM PI_Scenario__c
            WHERE Quote__c = :originalScenario.Quoteid__c AND isPrimary__c = true and Quote_Rev__c = :originalScenario.Quote_Rev__c
        ];
        for(PI_Scenario__c scenario : previousScenarios) {
            scenario.isPrimary__c = false;
        }
        update previousScenarios;

        PI_Scenario__c clonedScenario = originalScenario.clone(false, true, false, false);
        clonedScenario.Name__c = newScenarioName;
        clonedScenario.isPrimary__c = true;
        insert clonedScenario;

        // Query child line items
        List<PI_Scenario_Line_Item__c> originalLineItems = [
            SELECT Unit_List_Price__c, Unit_Book_Price__c, Line_cur_AuthorizedPrice__c, Line_Number__c, Parent_Scenario__c
            FROM PI_Scenario_Line_Item__c
            WHERE Parent_Scenario__c = :originalScenario.Id
        ];
        List<PI_Scenario_Line_Item__c> clonedLineItems = new List<PI_Scenario_Line_Item__c>();
        for (PI_Scenario_Line_Item__c item : originalLineItems) {
            PI_Scenario_Line_Item__c clonedItem = item.clone(false, true, false, false);
            clonedItem.Parent_Scenario__c = clonedScenario.Id;
            clonedLineItems.add(clonedItem);
        }
        if (!clonedLineItems.isEmpty()) {
            insert clonedLineItems;
        }
        //update new pi_scenario__c(Id=originalScenario.Id, isPrimary__c = false);
        
        Price_Manager_Page_Events__e myEvent = new Price_Manager_Page_Events__e(
            Record_Id__c = originalScenario.Quoteid__c,
            Message__c = 'Scenario cloned successfully'
        );
        Database.SaveResult results = EventBus.publish(myEvent);
        return new List<Id>{clonedScenario.Id};
    }
}