@isTest
private class CustomerSupportRequesterControllerTest {

    @TestSetup
    static void makeData(){
        List<SObject> toInsert = new List<SObject>();

        Contact con = new Contact(FirstName = 'Andrei',
                                  LastName = 'Mihalcea',
                                  Email = 'andrei.mihalcea@gmail.com');
        toInsert.add(con);

        Client__c clientWithoutCase = new Client__c(Name = 'Vlad Istodorescu',
                                                    Email_Address__c = 'vlad.istodorescu@gmail.com');
        toInsert.add(clientWithoutCase);

        Case c = new Case(Status = 'New',
                             Origin = 'Web',
                             Subject = 'Subject',
                             Description = 'Description',
                             SuppliedName = 'Andrei',
                             SuppliedEmail = 'andrei.mihalcea@gmail.com');
        toInsert.add(c);

        insert toInsert;
    }

    @isTest
    static void testCreateNewCaseAndRelateToContact(){
        Contact con = [SELECT Id, FirstName, LastName, Email
                       FROM Contact
                       WHERE Email = 'andrei.mihalcea@gmail.com'
                       LIMIT 1];

        String expectedSubject = 'Andrei Mihalcea - andrei.mihalcea@gmail.com'; 
        String description = 'Incident description!';
        String fullName = con.FirstName + ' ' + con.LastName;
                    
        Test.startTest();
            Id newCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToContact(con, description);
        Test.stopTest();

        Case createdCase = [SELECT Id, Subject, Description, SuppliedEmail, SuppliedName
                            FROM Case
                            WHERE Subject = :expectedSubject
                            LIMIT 1];

        Assert.areEqual(expectedSubject, createdCase.Subject, 'The Subject of the newly created Case is not what expected!');
        Assert.areEqual(description, createdCase.Description, 'The Description of the newly created Case is not what expected!');
        Assert.areEqual(con.Email, createdCase.SuppliedEmail, 'The SuppliedEmail of the newly created Case is not what expected!');
        Assert.areEqual(fullName, createdCase.SuppliedName, 'The SuppliedEmail of the newly created Case is not what expected!');
    }

    @isTest
    static void testCreateNewCaseAndRelateToClient(){
        Client__c client = [SELECT Id, Name, Email_Address__c 
                            FROM Client__c
                            WHERE Email_Address__c = 'vlad.istodorescu@gmail.com'
                            LIMIT 1];

        String expectedSubject = 'Vlad Istodorescu - vlad.istodorescu@gmail.com';
        String description = 'Incident description!';

        Test.startTest();
            Id newCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToClient(client, description);
        Test.stopTest();

        Case createdCase = [SELECT Id, Subject, Description, SuppliedEmail, SuppliedName
                            FROM Case
                            WHERE Subject = :expectedSubject
                            LIMIT 1];
        
        Assert.areEqual(expectedSubject, createdCase.Subject, 'The Subject of the newly created Case is not what expected!');
        Assert.areEqual(description, createdCase.Description, 'The Description of the newly created Case is not what expected!');
        Assert.areEqual(client.Email_Address__c, createdCase.SuppliedEmail, 'The SuppliedEmail of the newly created Case is not what expected!');
        Assert.areEqual(client.Name, createdCase.SuppliedName, 'The SuppliedEmail of the newly created Case is not what expected!');
    }

    @isTest
    static void testSendGuestEmailNoMatchFound() {
        Test.startTest();
            CustomerSupportRequesterController.sendGuestEmailNoMatchFound('notFound@test.com');
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailSupportRequestAlreadyOpen() {
        Contact con = [SELECT Id FROM Contact WHERE Email = 'andrei.mihalcea@gmail.com' LIMIT 1];
        Case c = [SELECT Id FROM Case WHERE SuppliedEmail = 'andrei.mihalcea@gmail.com' LIMIT 1];
    
        Test.startTest();
            CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(con.Id, c.Id);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailSupportRequestCreated() {
        Contact con = [SELECT Id FROM Contact WHERE Email = 'andrei.mihalcea@gmail.com' LIMIT 1];
        Case c = [SELECT Id FROM Case WHERE SuppliedEmail = 'andrei.mihalcea@gmail.com' LIMIT 1];
    
        Test.startTest();
            CustomerSupportRequesterController.sendEmailSupportRequestCreated(con.Id, c.Id);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();
    }
}
