public with sharing class RelationshipRequestController {
    @InvocableMethod(label='Create Relationship Request' description='Get Agreement Number and create Relationship Request.')
    public static List<ResponseOutput> createRelationshipRequest(List<RelationshipRequestInput> inputs) {        
        RelationshipRequestInput input = inputs[0];       
        Map<String,String> result = doValidationAndCreateRelationshipRequest(input);
        ResponseOutput output = new ResponseOutput();
        if(result.get('Success') != null) {
            output.Prompt = 'SPA Request created successfully.';
            output.newRequestId = Id.valueOf(result.get('Success'));
        } else if (result.get('Error') != null) {
            output.Prompt = result.get('Error');
            output.newRequestId = null;
        }
        return new List<ResponseOutput>{output};
    }

    private static Map<String,String> doValidationAndCreateRelationshipRequest(RelationshipRequestInput input) {
        Map<String,String> result = new Map<String,String>();        
        List<Id> createdIds = new List<Id>();
        //blank check
        if (String.isBlank(input.SapAgreementNumber)) {
            result.put('Error','Agreement number is required for Benefit Request.');
            return result;
        }
        // Check if agreement exists
        List<SapVistexAgreement__c> agreements = [
            SELECT Id,DirectAccountLookup__c,IndirectAccountLookup__c FROM SapVistexAgreement__c WHERE SapAgreementNumber__c = :input.SapAgreementNumber LIMIT 1
        ];
        if (agreements.isEmpty()) {
            result.put('Error','No Related Agreement found for the provided SAP Agreement Number.');
            return result;
        }

        if(input.DirectAccountId == null && input.InDirectAccountId == null) {
            result.put('Error','Direct or Indirect Account Ids are required for Relationship Request.');
            return result;
        }

        if(input.Operation == 'Expire') {
            for(SapVistexAgreement__c agreement : agreements) {
                if(agreement.DirectAccountLookup__c == input.DirectAccountId && agreement.IndirectAccountLookup__c == input.InDirectAccountId) {
                    break;//combination found
                } else{
                    result.put('Error','No Agreement found for the provided Direct and Indirect Account combination.');
                    return result;
                }
            }
        } else if(input.Operation == 'Add') {
            // Check if agreement exists for account combination
            List<SapVistexAgreement__c> existingAgreements = [
                SELECT Id,DirectAccountLookup__c,IndirectAccountLookup__c FROM SapVistexAgreement__c 
                WHERE DirectAccountLookup__c = :input.DirectAccountId 
                AND IndirectAccountLookup__c = : input.InDirectAccountId LIMIT 1
            ];
            if (!existingAgreements.isEmpty()) {
                result.put('Error','No Related Agreement found for the provided SAP Agreement Number.');
                return result;
            }
        } else {
            result.put('Error','Invalid Operation. Use "Expire" or "Add".');
            return result;
        }

        // Create SPA Request for Relationship Request
        Spa_Request__c newRequest = new Spa_Request__c();
        newRequest.RequestType__c = 'Relationship Request';
        newRequest.SapAgreementNumber__c = input.SapAgreementNumber;
        newRequest.Bill_To_Name__c = input.DirectAccountId;   
        newRequest.Quote_To_Name__c = input.InDirectAccountId;
        newRequest.Status__c = 'Draft';
        insert newRequest;

        SpaRequestEligibility__c eligibility = new SpaRequestEligibility__c();
        eligibility.SPARequest__c = newRequest.Id;
        eligibility.DirectAccount__c = input.DirectAccountId;  
        eligibility.IndirectAccount__c = input.InDirectAccountId;
        eligibility.SapAgreementNumber__c = input.SapAgreementNumber;
        eligibility.AEIndicator__c = input.Operation== 'Add' ? 'A' : 'E';
        if(input.Operation == 'Expire') {
            eligibility.EligibilityExpireDate__c = Date.today();
        } else {
            eligibility.EligibilityEffectiveDate__c = Date.today();
        }
        insert eligibility;
        result.put('Success',newRequest.Id);
        return result;
    }

    public class RelationshipRequestInput {
        @InvocableVariable(required=true)
        public String SapAgreementNumber;
        @InvocableVariable(label='Direct Account Name' required=true)
        public String DirectAccountId;
        @InvocableVariable(label='Indirect Account Name')
        public String InDirectAccountId;
        @InvocableVariable(description='Expire or Add' required=true)
        public String Operation;
    }

    public class ResponseOutput {
        @InvocableVariable
        public String Prompt;
        @InvocableVariable
        public Id newRequestId;
    }
}