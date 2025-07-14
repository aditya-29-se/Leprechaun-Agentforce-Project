public with sharing class QuoteApprovalQueueController {
    @AuraEnabled(cacheable=true)
    public static List<QuoteApprovalQueueDTO> getSubmitForAuthorizationQuotes() {
        List<QuoteApprovalQueueDTO> result = new List<QuoteApprovalQueueDTO>();
        for (Quote__c q : [
            SELECT Id, Name, Quote_Number__c, Submit_Date__c, Submitted_By__r.Name, Price_Authorizer_Name__c
            FROM Quote__c
            WHERE Status__c = 'Submitted for Authorization'
        ]) {
            result.add(new QuoteApprovalQueueDTO(
                q.Id,
                q.Quote_Number__c,
                q.Name,
                q.Submit_Date__c,
                q.Submitted_By__r != null ? q.Submitted_By__r.Name : null,
                q.Price_Authorizer_Name__c
            ));
        }
        return result;
    }

    public class QuoteApprovalQueueDTO {
        @AuraEnabled public Id Id;
        @AuraEnabled public String QuoteNumber;
        @AuraEnabled public String Name;
        @AuraEnabled public Date SubmittedDate;
        @AuraEnabled public String SubmittedByName;
        @AuraEnabled public String AuthorizerName;
        public QuoteApprovalQueueDTO(Id Id, String QuoteNumber, String Name, Date SubmittedDate, String SubmittedByName, String AuthorizerName) {
            this.Id = Id;
            this.QuoteNumber = QuoteNumber;
            this.Name = Name;
            this.SubmittedDate = SubmittedDate;
            this.SubmittedByName = SubmittedByName;
            this.AuthorizerName = AuthorizerName;
        }
    }

    @InvocableMethod(label='Not Auth Quote' description='Not Auth Quote' category='Quote__c')
    public static List<String> notAuthorizeQuote(List<AccountSummaryRequest> requests) {
        AccountSummaryRequest req = requests[0];
        Communication_Stream__c commStream = new Communication_Stream__c(
            Quote_ID__c = req.QuoteId,
            Note__c = req.Note
        );
        insert commStream;
        Price_Manager_Page_Events__e myEvent = new Price_Manager_Page_Events__e(
            Record_Id__c = req.QuoteId,
            Message__c = 'Note Created'
        );
        update new Quote__c(
            Id = req.QuoteId,
            Status__c = 'Not Authorized'
        );
        Database.SaveResult results = EventBus.publish(myEvent);
        return new List<String>{'A communication Stream Record has been added with the Reason you have Provided and Quote has been marked as "Not Authorized"'};
    }

    public class AccountSummaryRequest {
        @InvocableVariable(label='QuoteId' description='The ID of the Quote' required=true)
        public String QuoteId;
        @InvocableVariable(label='Note' description='The Note' required=true)
        public String Note;
    }
}