public with sharing class SpaRequestEligibilityGridController {
    @AuraEnabled(cacheable=true)
    public static List<SpaRequestEligibility__c> getSpaRequestEligibilities(Id parentId) {
        if (parentId == null) {
            return new List<SpaRequestEligibility__c>();
        }
        return [
            SELECT Id, SapAgreementNumber__c, DirectAccount__c, DirectAccount__r.Name, IndirectAccount__c, 
            IndirectAccount__r.Name, AEIndicator__c,EligibilityEffectiveDate__c,  EligibilityExpireDate__c
            FROM SpaRequestEligibility__c
            WHERE SPARequest__c = :parentId
        ];
    }
}