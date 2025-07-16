public with sharing class QuoteAuthorizationController {
    public class QuoteAuthorizationRequest {
        @InvocableVariable(label='Quote Id' description='The Id of the Quote to authorize' required=true)
        public Id quoteId;
        @InvocableVariable(label='Note' description='The note for the communication stream' required=true)
        public String note;
    }

    @InvocableMethod(label='Authorize Quote and Create Communication Stream' description='Marks a Quote as Authorized and creates a Communication_Stream__c record, then publishes a platform event.')
    public static List<id> authorizeQuoteAndCreateCommStream(List<QuoteAuthorizationRequest> requests) {
        //for (QuoteAuthorizationRequest req : requests) {
            // Mark Quote as Authorized
            Quote__c quoteToUpdate = [SELECT Id, Status__c FROM Quote__c WHERE Id = :requests[0].quoteId LIMIT 1];
            quoteToUpdate.Status__c = 'Authorized';
            update quoteToUpdate;

            // Create Communication_Stream__c record
            if(string.isNotBlank(requests[0].note)){
                Communication_Stream__c comm = new Communication_Stream__c();
                comm.Quote_ID__c = requests[0].quoteId;
                comm.Note__c = requests[0].note;
                insert comm;
            }

            // Publish platform event
            Price_Manager_Page_Events__e event = new Price_Manager_Page_Events__e(
                Record_Id__c = requests[0].quoteId,
                Message__c = 'Quote has been Authorized'
            );
            EventBus.publish(event);
        //}
        return new List<Id>{requests[0].quoteId};
    }
}