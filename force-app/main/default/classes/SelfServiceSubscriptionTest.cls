@isTest
public class SelfServiceSubscriptionTest {
    @testSetup
    public static void setup() {
        List<Product2> products = new List<Product2>();
        for(Integer i=0;i<5;i++){
            Product2 product = new Product2();
            product.Name = 'Test Product '+i;
            products.add(product);
        }
        insert products;
    }

    @isTest
    public static void testCreateQuote(){
        List<Id> productIds = new List<Id>();
        for(Product2 product : [SELECT Id, Name FROM Product2 WHERE Name LIKE 'Test Product%']){
            productIds.add(product.Id);
        }
        SelfServiceSubscriptionController sscObj = new SelfServiceSubscriptionController();
        sscObj.createQuote(productIds, 'New Quote', 12);
        Opportunity oppty = sscObj.getOpportunity();
        oppty.StageName='Closed - Won';
        update oppty;
        sscObj.convertQuoteToSubscription(oppty);
        List<SBQQ__QuoteLine__c> quoteLines = sscObj.getQuoteLines();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            for(Id productId : productIds){
                if(quoteLine.SBQQ__Product__c == productId){
                    System.assertEquals(productId, quoteLine.SBQQ__Product__c);
                }
            }
        }

    }
}