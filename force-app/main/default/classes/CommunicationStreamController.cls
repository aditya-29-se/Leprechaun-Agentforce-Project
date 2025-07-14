public without sharing class CommunicationStreamController {
    public class CommStreamWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Note;
        @AuraEnabled public String Category;
        @AuraEnabled public String CommentedBy;
        @AuraEnabled public String CreatedByName;
        @AuraEnabled public DateTime CreatedDate;
        public CommStreamWrapper(Communication_Stream__c comm) {
            Id = comm.Id;
            Name = comm.Name;
            Note = comm.Note__c;
            Category = comm.Category__c;
            CommentedBy = comm.Commented_By__c;
            CreatedByName = comm.CreatedBy != null ? comm.CreatedBy.Name : null;
            CreatedDate = comm.CreatedDate;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<CommStreamWrapper> getRecordsComm(Id quoteId) {
        List<Communication_Stream__c> comms = [SELECT Id, Name, Note__c, Category__c, Commented_By__c, CreatedDate, CreatedBy.Name FROM Communication_Stream__c WHERE Quote_ID__c = :quoteId ORDER BY CreatedDate DESC];
        List<CommStreamWrapper> wrappers = new List<CommStreamWrapper>();
        for (Communication_Stream__c comm : comms) {
            wrappers.add(new CommStreamWrapper(comm));
        }
        return wrappers;
    }

    @InvocableMethod(label='Get Line Previous Value' description='Get Line Previous Value' category='PI_Deal_History2__c')
    public static List<PI_Deal_History2__c> getLinePrevVal(List<AccountSummaryRequestForLine> requests) {
        return [select id,Line_cur_AuthorizedPrice__c,Quote_Rev__c,Line_Number__c from PI_Deal_History2__c where Line_Number__c = :requests[0].LineNumber and Quote_Rev__c = :Decimal.valueOf(requests[0].SpdRev)];
    }

    public class AccountSummaryRequestForLine {
        @InvocableVariable(label='LineNumber' description='The number of the line' required=true)
        public String LineNumber;
        @InvocableVariable(label='SpdRev' description='The SpdRev' required=true)
        public String SpdRev;
    }
}