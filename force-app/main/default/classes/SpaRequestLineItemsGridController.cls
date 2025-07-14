public with sharing class SpaRequestLineItemsGridController {
    @AuraEnabled(cacheable=true)
    public static List<SPA_Request_Line_Item__c> getSpaRequestLineItems(Id parentId) {
        if (parentId == null) {
            return new List<SPA_Request_Line_Item__c>();
        }
        return [
            SELECT Id, Item_Code__c, Item_Description__c, Unit_Book_Price__c, Unit_Profile_Price__c, ProfileMultiplier__c, Requested_Net_Multiplier_Rebate__c, AME_Indicator__c, Requested_Net_Price_Rebate__c
            FROM SPA_Request_Line_Item__c
            WHERE Spa_Request__c = :parentId
        ];
    }
}