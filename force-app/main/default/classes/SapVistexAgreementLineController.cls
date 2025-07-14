public with sharing class SapVistexAgreementLineController {
    @AuraEnabled(cacheable=true)
    public static List<SapVistexAgreementLine__c> getAgreementLines(String agreementNumber) {
        if (String.isBlank(agreementNumber)) {
            return new List<SapVistexAgreementLine__c>();
        }
        return [
            SELECT Id, Name, SAP_Agreement_Number__c /* Add other fields as needed */
            FROM SapVistexAgreementLine__c
            WHERE SAP_Agreement_Number__c = :agreementNumber
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<SapVistexAgreementLine__c> getAgreementLinesByAgreementId(Id recordId) {
        if (recordId == null) {
            return new List<SapVistexAgreementLine__c>();
        }
        SapVistexAgreement__c agreement = [
            SELECT SapAgreementNumber__c FROM SapVistexAgreement__c WHERE Id = :recordId LIMIT 1
        ];
        if (agreement == null || agreement.SapAgreementNumber__c == null) {
            return new List<SapVistexAgreementLine__c>();
        }
        return [
            SELECT Id, Name, SAP_Agreement_Number__c, Item_Code__c, Unit_List_Price__c
            FROM SapVistexAgreementLine__c
            WHERE SAP_Agreement_Number__c = :agreement.SapAgreementNumber__c
        ];
    }
}