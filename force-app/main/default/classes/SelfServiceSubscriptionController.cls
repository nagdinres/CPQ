public with sharing class SelfServiceSubscriptionController {
    
    private SBQQ__Quote__c quote;
    private List<SBQQ__QuoteLine__c> quoteLines;
    private Opportunity oppty;

    public SBQQ__Quote__c getQuote(){
        return quote;
    }

    public List<SBQQ__QuoteLine__c> getQuoteLines(){
        return quoteLines;
    }

    public Opportunity getOpportunity(){
        return oppty;
    }

    public void createQuote(List<Id> productIds, String quoteType, Integer term){
        quote = populateQuoteFields(quoteType, term);
        if(Schema.sObjectType.SBQQ__Quote__c.isCreateable()){
            try{
                insert quote;
            }
            catch(DMLException excp){
                System.debug('Exception occurred: '+excp.getMessage());
            }
        }
        
        quoteLines = populateQuoteLineFields(productIds, quote.Id);
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isCreateable()){
            try{
                insert quoteLines;
            }
            catch(DMLException excp){
                System.debug('Exception occurred: '+excp.getMessage());
            }
        }

        oppty = createOpportunity(quote, quoteLines);
    }

    public Opportunity createOpportunity(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> quoteLines){
        quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Id=:quote.Id];
        Opportunity oppty = populateOpptyFields(quote);
        if(Schema.sObjectType.Opportunity.isCreateable()){
            try{
                insert oppty;
            }
            catch(DMLException excp){
                System.debug('Exception occurred: '+excp.getMessage());
            }
        }

        List<OpportunityLineItem> oppLineItems = populateOpptyLineItemFields(quoteLines, oppty.Id);
        if(Schema.sObjectType.OpportunityLineItem.isCreateable()){
            try{
                insert oppLineItems;
            }
            catch(DMLException excp){
                System.debug('Exception occurred: '+excp.getMessage());
            }
        }
        return oppty;
    }

    public void convertQuoteToSubscription(Opportunity oppty){
        if(!oppty.StageName.equalsIgnoreCase('Closed - Won')){
            return;
        }
        else{
            Contract cont = populateContractFields(oppty);
            if(Schema.sObjectType.Contract.isCreateable()){
                try{
                    insert cont;
                }
                catch(DMLException excp){
                    System.debug('Exception occurred: '+excp.getMessage());
                }
            }
            List<OpportunityLineItem> opptyLineItems =[SELECT Id, Name, Product2Id, ListPrice, UnitPrice, TotalPrice FROM OpportunityLineItem WHERE Id=: oppty.Id WITH SECURITY_ENFORCED];
            List<ContractLineItem> subscriptions = populateContractLineItemFields(opptyLineItems, cont.Id);
            if(Schema.sObjectType.ContractLineItem.isCreateable()){
                try{
                    insert subscriptions;
                }
                catch(DMLException excp){
                    System.debug('Exception occurred: '+excp.getMessage());
                }
            }
        }
    }

    public void updateContract(Contract cont){
        System.debug('');
    }

    public SBQQ__Quote__c populateQuoteFields(String quoteType, Integer term){
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Type__c = quoteType;
        quote.SBQQ__SubscriptionTerm__c = term;
        return quote;
    }

    public List<SBQQ__QuoteLine__c> populateQuoteLineFields(List<Id> productIds, Id quoteId){
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        for(Product2 prod : [SELECT Id, Name FROM Product2 WHERE Id IN: productIds WITH SECURITY_ENFORCED]){
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.SBQQ__Product__c = prod.Id;
            quoteLine.SBQQ__Quote__c = quoteId;
            quoteLines.add(quoteLine);
        }
        return quoteLines;
    }

    public Opportunity populateOpptyFields(SBQQ__Quote__c quote){
        Opportunity opp = new Opportunity();
        opp.Name = 'Opportunity of quote# '+quote.Name;
        opp.StageName = 'Prospecting';
        opp.CloseDate = System.today();
        //opp.SBQQ__PrimaryQuote__c = quote.Id;
        return opp;
    }

    public List<OpportunityLineItem> populateOpptyLineItemFields(List<SBQQ__QuoteLine__c> quoteLines, Id oppId){
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            OpportunityLineItem oppLineItem = new OpportunityLineItem();
            oppLineItem.SBQQ__QuoteLine__c = quoteLine.Id;
            oppLineItem.Product2Id = quoteLine.SBQQ__Product__c;
            oppLineItem.OpportunityId = oppId;
            oppLineItems.add(oppLineItem);
        }
        return oppLineItems;
    }

    public Contract populateContractFields(Opportunity opp){
        Contract cont = new Contract();
        cont.SBQQ__Opportunity__c = opp.Id;
        cont.SBQQ__Quote__c = opp.SBQQ__PrimaryQuote__c;
        cont.Status = 'Active';
        return cont;
    }

    public List<ContractLineItem> populateContractLineItemFields(List<OpportunityLineItem> opptyLineItems, Id contractId){
        List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
        for(OpportunityLineItem opptyLineItem : opptyLineItems){
            ContractLineItem contractLineItem = new ContractLineItem();
            //contractLineItem.Product2Id = opptyLineItem.Product2Id;
            //contractLineItem.ListPrice = opptyLineItem.ListPrice;
            contractLineItem.UnitPrice = opptyLineItem.UnitPrice;
            //contractLineItem.TotalPrice = opptyLineItem.TotalPrice;
            contractLineItem.ServiceContractId = contractId;
            contractLineItems.add(contractLineItem);
        }
        return contractLineItems;
    }
}