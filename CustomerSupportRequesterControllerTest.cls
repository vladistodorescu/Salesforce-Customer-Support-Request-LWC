// CustomerSupportRequesterControllerTest.cls
@isTest
private class CustomerSupportRequesterControllerTest {

    @TestSetup
    static void makeData(){
        List<SObject> toInsert = new List<SObject>();
        List<Case> casesToInsert = new List<Case>();

        Case caseForClient = new Case(Status = 'New',
                                      Origin = 'Web',
                                      Subject = 'Adriana Maria - adriana.maria@gmail.com',
                                      Description = 'Incident Description',
                                      SuppliedName = 'Adriana Maria',
                                      SuppliedEmail = 'adriana.maria@gmail.com');
        casesToInsert.add(caseForClient);

        Case caseForContact = new Case(Status = 'New',
                                       Origin = 'Web',
                                       Subject = 'Mihai Popescu - mihai.popescu@gmail.com',
                                       Description = 'Incident Description',
                                       SuppliedName = 'Mihai Popescu',
                                       SuppliedEmail = 'mihai.popescu@gmail.com');
        casesToInsert.add(caseForContact);

        Case caseForClientEmailOnly = new Case(Status = 'New',
                                               Origin = 'Web',
                                               Subject = 'G. Popescu - george.popescu@gmail.com',
                                               Description = 'Incident Description',
                                               SuppliedName = 'G. Popescu',
                                               SuppliedEmail = 'george.popescu@gmail.com');
        casesToInsert.add(caseForClientEmailOnly);

        insert casesToInsert;

        Contact conWithoutCase = new Contact(FirstName = 'Andrei',
                                             LastName = 'Mihalcea',
                                             Email = 'andrei.mihalcea@gmail.com');
        toInsert.add(conWithoutCase);

        Contact conWithCase = new Contact(FirstName = 'Mihai',
                                          LastName = 'Popescu',
                                          Email = 'mihai.popescu@gmail.com',
                                          Related_Case__c = caseForContact.Id);
        toInsert.add(conWithCase);

        Client__c clientWithoutCase = new Client__c(Name = 'Vlad Istodorescu',
                                                    Email_Address__c = 'vlad.istodorescu@gmail.com');
        toInsert.add(clientWithoutCase);

        Client__c clientWithCase = new Client__c(Name = 'Adriana Maria',
                                                 Email_Address__c = 'adriana.maria@gmail.com',
                                                 Related_Case__c = caseForClient.Id);
        toInsert.add(clientWithCase);

        Client__c clientIncorrectFirstName = new Client__c(Name = 'D. Istodorescu',        // no match match LIKE 'Vlad%'
                                                           Email_Address__c = 'dragos.istodorescu@gmail.com');
        toInsert.add(clientIncorrectFirstName);

        Client__c clientIncorrectFirstNameWithCase = new Client__c(Name = 'G. Popescu',
                                                                   Email_Address__c = 'george.popescu@gmail.com',
                                                                   Related_Case__c = caseForClientEmailOnly.Id);
        toInsert.add(clientIncorrectFirstNameWithCase);
                                            
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
        Contact conWithRequestAlreadyOpen = [SELECT Id, Related_Case__c FROM Contact WHERE Email = 'mihai.popescu@gmail.com' LIMIT 1];
        String relatedCaseId = conWithRequestAlreadyOpen.Related_Case__c;
        Case supportRequest = [SELECT Id FROM Case WHERE Id = :relatedCaseId LIMIT 1];
    
        Test.startTest();
            CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(conWithRequestAlreadyOpen.Id, supportRequest.Id);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailSupportRequestCreated() {
        Contact conWithRequestCreated = [SELECT Id FROM Contact WHERE Email = 'mihai.popescu@gmail.com' LIMIT 1];
        Case supportRequest = [SELECT Id FROM Case WHERE SuppliedEmail = 'mihai.popescu@gmail.com' LIMIT 1];
    
        Test.startTest();
            CustomerSupportRequesterController.sendEmailSupportRequestCreated(conWithRequestCreated.Id, supportRequest.Id);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();
    }

    @isTest
    static void testProcessCustomerSupportRequestWithLastNameExistingClientNoContactNoRequestOpen(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Vlad';
        wrapper.lastName = 'Istodorescu';
        wrapper.email = 'vlad.istodorescu@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Vlad Istodorescu - vlad.istodorescu@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Client__c clientRecord = [SELECT Id, Name, Related_Contact__c, Related_Case__c
                                  FROM Client__c 
                                  WHERE Name = 'Vlad Istodorescu'];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Vlad'
                                 AND LastName = 'Istodorescu'
                                 AND Email = 'vlad.istodorescu@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('CREATED', resultStatus, 'The result Status should be "CREATED"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The created Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The created Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The created Support Request does not have the expected Description!');
        Assert.areEqual('Vlad Istodorescu', supportRequests[0].SuppliedName, 'The created Support Request does not have expected SuppliedName!');
        Assert.areEqual('vlad.istodorescu@gmail.com', supportRequests[0].SuppliedEmail, 'The created Support Request does not have expected SuppliedEmail!');
        
        Assert.areNotEqual(null, clientRecord.Related_Contact__c, 'The Client record should have a Contact record related!');
        Assert.areNotEqual(null, clientRecord.Related_Case__c, 'The Client reocrd should have a Case record related!');

        Assert.areNotEqual(null, contactRecord.Related_Case__c, 'The Contact record should have a Case record related!');
    }

    @isTest
    static void testProcessCustomerSupportRequestWithLastNameExistingClientNoContactWithRequestOpen(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Adriana';
        wrapper.lastName = 'Maria';
        wrapper.email = 'adriana.maria@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Adriana Maria - adriana.maria@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Client__c clientRecord = [SELECT Id, Name, Related_Contact__c, Related_Case__c
                                  FROM Client__c 
                                  WHERE Name = 'Adriana Maria'];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Adriana'
                                 AND LastName = 'Maria'
                                 AND Email = 'adriana.maria@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('ALREADY_OPEN', resultStatus, 'The result should be "ALREADY_OPEN"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The searched Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The searched Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The searched Support Request does not have the expected Description!');
        Assert.areEqual('Adriana Maria', supportRequests[0].SuppliedName, 'The searched Support Request does not have expected SuppliedName!');
        Assert.areEqual('adriana.maria@gmail.com', supportRequests[0].SuppliedEmail, 'The searched Support Request does not have expected SuppliedEmail!');
    }

    @isTest
    static void testProcessCustomerSupportRequestWithLastNameNoClientWithContactNoRequestOpen(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Andrei';
        wrapper.lastName = 'Mihalcea';
        wrapper.email = 'andrei.mihalcea@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Andrei Mihalcea - andrei.mihalcea@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Andrei'
                                 AND LastName = 'Mihalcea'
                                 AND Email = 'andrei.mihalcea@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('CREATED', resultStatus, 'The result Status should be "CREATED"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The created Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The created Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The created Support Request does not have the expected Description!');
        Assert.areEqual('Andrei Mihalcea', supportRequests[0].SuppliedName, 'The created Support Request does not have expected SuppliedName!');
        Assert.areEqual('andrei.mihalcea@gmail.com', supportRequests[0].SuppliedEmail, 'The created Support Request does not have expected SuppliedEmail!');

        Assert.areNotEqual(null, contactRecord.Related_Case__c, 'The Contact record should have a Case record related!');
    }

    @isTest
    static void testProcessCustomerSupportRequestWithLastNameNoClientWithContactWithRequestOpen(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Mihai';
        wrapper.lastName = 'Popescu';
        wrapper.email = 'mihai.popescu@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Mihai Popescu - mihai.popescu@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Mihai'
                                 AND LastName = 'Popescu'
                                 AND Email = 'mihai.popescu@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('ALREADY_OPEN', resultStatus, 'The result should be "ALREADY_OPEN"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The searched Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The searched Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The searched Support Request does not have the expected Description!');
        Assert.areEqual('Mihai Popescu', supportRequests[0].SuppliedName, 'The searched Support Request does not have expected SuppliedName!');
        Assert.areEqual('mihai.popescu@gmail.com', supportRequests[0].SuppliedEmail, 'The searched Support Request does not have expected SuppliedEmail!');
    }

    @isTest
    static void testProcessCustomerSupportRequestWithLastNameNoClientNoContactFound() {
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Ioana';
        wrapper.lastName = 'Stanescu';
        wrapper.email = 'ioana.stanescu@gmail.com';
        wrapper.description = 'Incident Description';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        Assert.areEqual('NOT_FOUND', resultStatus, 'The result Status should be "NOT_FOUND"!');
    }

    @isTest
    static void testProcessCustomerSupportRequestNoLastNameExistingClientNoContactNoRequest(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Vlad';
        wrapper.email = 'vlad.istodorescu@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Vlad Istodorescu - vlad.istodorescu@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                              FROM Case
                              WHERE Subject =: expectedSubject];

        Client__c clientRecord = [SELECT Id, Name, Related_Contact__c, Related_Case__c
                                  FROM Client__c 
                                  WHERE Name = 'Vlad Istodorescu'];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Vlad'
                                 AND LastName = 'Istodorescu'
                                 AND Email = 'vlad.istodorescu@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('CREATED', resultStatus, 'The result Status should be "CREATED"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The created Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The created Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The created Support Request does not have the expected Description!');
        Assert.areEqual('Vlad Istodorescu', supportRequests[0].SuppliedName, 'The created Support Request does not have expected SuppliedName!');
        Assert.areEqual('vlad.istodorescu@gmail.com', supportRequests[0].SuppliedEmail, 'The created Support Request does not have expected SuppliedEmail!');
        
        Assert.areNotEqual(null, clientRecord.Related_Contact__c, 'The Client record should have a Contact record related!');
        Assert.areNotEqual(null, clientRecord.Related_Case__c, 'The Client reocrd should have a Case record related!');

        Assert.areNotEqual(null, contactRecord.Related_Case__c, 'The Contact record should have a Case record related!');
    }

    @isTest
    static void testProcessCustomerSupportRequestNoLastNameExistingClientNoContactWithRequestOpen(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Adriana';
        wrapper.email = 'adriana.maria@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Adriana Maria - adriana.maria@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                              FROM Case
                              WHERE Subject =: expectedSubject];

        Client__c clientRecord = [SELECT Id, Related_Contact__c, Related_Case__c
                                  FROM Client__c 
                                  WHERE Name = 'Adriana Maria'];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Adriana'
                                 AND LastName = 'Maria'
                                 AND Email = 'adriana.maria@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('ALREADY_OPEN', resultStatus, 'The result Status should be "ALREADY_OPEN"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The searched Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The searched Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The searched Support Request does not have the expected Description!');
        Assert.areEqual('Adriana Maria', supportRequests[0].SuppliedName, 'The searched Support Request does not have expected SuppliedName!');
        Assert.areEqual('adriana.maria@gmail.com', supportRequests[0].SuppliedEmail, 'The searched Support Request does not have expected SuppliedEmail!');
    }

    @isTest
    static void testProcessCustomerSupportRequestNoLastNameExistingClientByEmailOnlyNoContactNoRequest(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Dragos';
        wrapper.email = 'dragos.istodorescu@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'D. Istodorescu - dragos.istodorescu@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Client__c clientRecord = [SELECT Id, Name, Email_Address__c, Related_Contact__c, Related_Case__c
                                  FROM Client__c 
                                  WHERE Name = 'D. Istodorescu'];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Dragos'
                                 AND LastName = 'Istodorescu'
                                 AND Email = 'dragos.istodorescu@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('CREATED', resultStatus, 'The result Status should be "CREATED"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The created Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The created Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The created Support Request does not have the expected Description!');
        Assert.areEqual('D. Istodorescu', supportRequests[0].SuppliedName, 'The created Support Request does not have expected SuppliedName!');
        Assert.areEqual('dragos.istodorescu@gmail.com', supportRequests[0].SuppliedEmail, 'The created Support Request does not have expected SuppliedEmail!');
    }

    @isTest
    static void testProcessCustomerSupportRequestNoLastNameExistingClientByEmailOnlyNoContactWithRequestOpen(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'George';
        wrapper.email = 'george.popescu@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'G. Popescu - george.popescu@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Client__c clientRecord = [SELECT Id, Name, Email_Address__c, Related_Contact__c, Related_Case__c
                                  FROM Client__c 
                                  WHERE Name = 'G. Popescu'];

        Contact contactRecord = [SELECT Id, FirstName, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'George'
                                 AND LastName = 'Popescu'
                                 AND Email = 'george.popescu@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('ALREADY_OPEN', resultStatus, 'The result Status should be "ALREADY_OPEN"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The searched Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The searched Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The searched Support Request does not have the expected Description!');
        Assert.areEqual('G. Popescu', supportRequests[0].SuppliedName, 'The searched Support Request does not have expected SuppliedName!');
        Assert.areEqual('george.popescu@gmail.com', supportRequests[0].SuppliedEmail, 'The searched Support Request does not have expected SuppliedEmail!');
    }

    @isTest
    static void testProcessCustomerSupportRequestNoLastNameNoClientWithContactNoRequest(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Andrei';
        wrapper.email = 'andrei.mihalcea@gmail.com';
        wrapper.description = 'Incident Description';

        String expectedSubject = 'Andrei Mihalcea - andrei.mihalcea@gmail.com';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        List<Case> supportRequests = [SELECT Id, Subject, Status, Origin, Description, SuppliedName, SuppliedEmail
                                      FROM Case
                                      WHERE Subject =: expectedSubject];

        Contact contactRecord = [SELECT Id, FirstName, Email, LastName, Related_Case__c
                                 FROM Contact
                                 WHERE FirstName = 'Andrei'
                                 AND LastName = 'Mihalcea'
                                 AND Email = 'andrei.mihalcea@gmail.com'];

        Assert.areEqual(1, supportRequests.size(), 'The Support Request List size should be 1 (perfect match)!');
        Assert.areEqual('CREATED', resultStatus, 'The result Status should be "CREATED"!');
        Assert.areEqual('New', supportRequests[0].Status, 'The created Support Request should have Status "New"!');
        Assert.areEqual('Web', supportRequests[0].Origin, 'The created Support Request should have Origin "Web"!');
        Assert.areEqual('Incident Description', supportRequests[0].Description, 'The created Support Request does not have the expected Description!');
        Assert.areEqual('Andrei Mihalcea', supportRequests[0].SuppliedName, 'The created Support Request does not have expected SuppliedName!');
        Assert.areEqual('andrei.mihalcea@gmail.com', supportRequests[0].SuppliedEmail, 'The created Support Request does not have expected SuppliedEmail!');

        Assert.areNotEqual(null, contactRecord.Related_Case__c, 'The Contact record should have a Case record related!');
    }

    @isTest
    static void testProcessCustomerSupportRequestNoLastNameNoClientNoContactFound(){
        CustomerSupportRequesterController.CustomerSupportRequestWrapper wrapper = new CustomerSupportRequesterController.CustomerSupportRequestWrapper();
        wrapper.firstName = 'Marina';
        wrapper.email = 'marina.miroslav@gmail.com';
        wrapper.description = 'Incident Description';

        Test.startTest();
            String resultStatus = CustomerSupportRequesterController.processCustomerSupportRequest(wrapper);
            Assert.areEqual(1, Limits.getEmailInvocations(), 'Expected exactly 1 email to be sent');
        Test.stopTest();

        Assert.areEqual('NOT_FOUND', resultStatus, 'The result Status should be "NOT_FOUND"!');
    }
} 
