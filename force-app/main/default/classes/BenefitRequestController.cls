public with sharing class BenefitRequestController {
    @InvocableMethod(label='Create Benefit Request' description='Get Agreement Number and create Benefit Request.')
    public static List<ResponseOutput> createBenefitRequest(List<RequestInput> inputs) {        
        RequestInput input = inputs[0];       
        Map<String,String> result = doValidationAndCreateBenefitRequest(input);
        ResponseOutput output = new ResponseOutput();
        String baseUrl = 'https://orgfarm-8ad19981fe-dev-ed.develop.lightning.force.com';
        if(result.get('Success') != null) {
            output.Prompt = '<b><span style="color:green;">SPA Request created successfully.</span></b><br/><a href="' + baseUrl + '/' + result.get('Success') + '" target="_blank">View Request</a>';
            output.newRequestId = Id.valueOf(result.get('Success'));
        } else if (result.get('Error') != null) {
            output.Prompt = '<b><span style="color:red;">' + result.get('Error') + '</span></b><br/><a href="' + baseUrl + '/' + result.get('Active_Request') + '" target="_blank">'+result.get('Name')+'</a>';
            output.newRequestId = Id.valueOf(result.get('Active_Request'));
        }
        return new List<ResponseOutput>{output};
    }

    private static Map<String,String> doValidationAndCreateBenefitRequest(RequestInput input) {
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

        // Check for open SPA Request for this agreement
        List<Spa_Request__c> openRequests = [
            SELECT Id,Name FROM Spa_Request__c 
            WHERE SapAgreementNumber__c = :input.SapAgreementNumber 
            AND Status__c IN ('Draft','Submitted for Authorization','Authorized','Acknowledged') LIMIT 1
        ];
        if (!openRequests.isEmpty()) {
            result.put('Error','Active Request already exists for this Agreement.');
            result.put('Active_Request',openRequests[0].Id);
            result.put('Name',openRequests[0].Name);
            return result;
        }
        // Create SPA Request
        Spa_Request__c newRequest = new Spa_Request__c();
        newRequest.RequestType__c = 'Benefit Request';
        newRequest.SapAgreementNumber__c = input.SapAgreementNumber;
        newRequest.Bill_To_Name__c = agreements[0].DirectAccountLookup__c;
        newRequest.Quote_To_Name__c = agreements[0].IndirectAccountLookup__c;
        newRequest.Status__c = 'Draft';
        insert newRequest;
        result.put('Success',newRequest.Id);
        result.put('Name',newRequest.Name);

        if(input.lines == null || input.lines.isEmpty()) {
            result.put('Error','At least one Benefit Line Item is required.');
            return result;
        }
        List<Spa_Request_Line_Item__c> lineItems = new List<Spa_Request_Line_Item__c>();
        for(BenefitRequestInput lineItem : input.lines) {
            if (String.isBlank(lineItem.ItemCode) || lineItem.ListPrice == null || String.isBlank(lineItem.Operation)) {
                result.put('Error','Item Code, List Price and Operation are required for each Benefit Line Item.');
                return result;
            }
            if (lineItem.Operation != 'Add' && lineItem.Operation != 'Modify' && lineItem.Operation != 'Expire') {
                result.put('Error','Invalid Operation. Use "Add", "Modify" or "Expire".');
                return result;
            }
            lineItems.add(createSpaRequestLineItems(lineItem, newRequest.Id));          
        }
        if (lineItems.isEmpty()) {
            result.put('Error','No valid line items to create.');
            return result;
        }
        insert lineItems;
        //createSpaRequestLineItems(newRequest.Id);    
        return result;
    }

    private static Spa_Request_Line_Item__c createSpaRequestLineItems(BenefitRequestInput input, Id requestId) {
        //List<Spa_Request_Line_Item__c> lineItems = new List<Spa_Request_Line_Item__c>();
        Spa_Request_Line_Item__c newLineItem = new Spa_Request_Line_Item__c();
        newLineItem.Spa_Request__c = requestId;
        newLineItem.Item_Code__c = input.ItemCode;
        newLineItem.Item_Description__c = 'Benefit Request Item';
        newLineItem.Unit_List_Price__c = Decimal.valueOf(input.ListPrice);
        //newLineItem.Requested_Net_Multiplier_Rebate__c = 0.0; // Set appropriate values
        newLineItem.AME_Indicator__c = input.Operation=='Add' ? 'A' : input.Operation=='Modify' ? 'M' : 'E';
        //newLineItem.Requested_Net_Price_Rebate__c = 0.0; // Set appropriate values
        newLineItem.Requested_Expiration_Date__c = input.ExpirationDate;
        //lineItems.add(newLineItem);
        //insert newLineItem;
        return newLineItem;
    }

    public class RequestInput{
        @InvocableVariable(label='Agreement Number' required=true)
        public String SapAgreementNumber;
        @InvocableVariable(label='Benefit Lines' required=true)
        public List<BenefitRequestInput> lines;
    }
    
    public class BenefitRequestInput {
        @InvocableVariable(label='Item Code' required=true)
        public String ItemCode;
        @InvocableVariable(label='List Price' required=true)
        public String ListPrice;
        @InvocableVariable(description='Add/Modify/Expire' required=true)
        public String Operation;
        @InvocableVariable(label='Requested Expiration Date')
        public Date ExpirationDate;
    }

    public class ResponseOutput {
        @InvocableVariable
        public String Prompt;
        @InvocableVariable
        public Id newRequestId;
    }    
}