public without sharing class Approval_HistoryController {
    @AuraEnabled(cacheable=true)
    public static List<Approval_History__c> getAdhocApprovalHistory(Id quoteId) {
        return [
            SELECT Id, Line_Item_Number__c, Product_Description__c, Quantity__c, PDCAT__c, Ad_Hoc_Price_Status__c, Unit_List_Price__c
            FROM Approval_History__c
            WHERE Quote__c = :quoteId
              AND Ad_Hoc_Price_Status__c != null
        ];
    }

    @InvocableMethod(label='Approve Adhoc Approval Histories' description='Approve Adhoc Approval Histories' category='Approval_History__c')
    public static List<String> approveAdhocApprovalHistories(List<AccountSummaryRequest> requests) {
        AccountSummaryRequest req = requests[0];
        List<approval_history__c> approvalHistories = new List<approval_history__c>();
        for(Id adhocApprovalHistoryId : req.adhocApprovalHistoryIds) {
            approvalHistories.add(new  Approval_History__c(Id=adhocApprovalHistoryId,Ad_Hoc_Price_Status__c = 'Authorized'));
        }
        update approvalHistories;
        Price_Manager_Page_Events__e myEvent = new Price_Manager_Page_Events__e(
            Record_Id__c = req.adhocApprovalHistoryIds[0],
            Message__c = 'Adhoc Approval Histories Approved'
        );
        Database.SaveResult results = EventBus.publish(myEvent);
        return new List<String>{'A communication Stream Record has been added with the Reason you have Provided and Quote has been marked as "Not Authorized"'};
    }

    public class AccountSummaryRequest {
        @InvocableVariable(label='AdhocApprovalHistoryIds' description='The ID of Adhoc Approval History records' required=true)
        public List<Id> adhocApprovalHistoryIds;
    }
}