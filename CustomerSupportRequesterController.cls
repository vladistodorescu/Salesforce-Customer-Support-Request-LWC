public with sharing class CustomerSupportRequesterController {
    public class CustomerSupportRequestWrapper{
        @AuraEnabled public String lastName {get; set;} // ' {get; set;}' after the definition of wrapper class, creates stock getters and setters, since no special processing needed
        @AuraEnabled public String firstName {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String description {get; set;}
    }

    @AuraEnabled
    public static String processCustomerSupportRequest(CustomerSupportRequestWrapper wrapper){
        // we have Last Name (all others required) 
        if (wrapper.lastName != null){
            String fullName = wrapper.lastName + ' ' + wrapper.firstName;

            List<Client__c> searchedClients = [SELECT Id, Name, Email_Address__c, Related_Case__c, Related_Contact__c
                                                FROM Client__c 
                                                WHERE Name =: fullName
                                                AND Email_Address__c =: wrapper.email];

            // Client perfect match found (full name and email), look for related Case
            if (searchedClients.size() == 1){
                // Client doesn't have Case related, create one with wrapper data, and send confirmation Email
                if (searchedClients[0].Related_Case__c == null){
                    // create Case and store ID for sending Email
                    Id relatedCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToClient(searchedClients[0], wrapper.description);
                    // we need a Contact in order to send an Email with according Case data
                    // so that if the matching Client doesn't have a Contact related, we create one and relate it
                    if (searchedClients[0].Related_Contact__c == null){
                        searchedClients[0].Related_Contact__c = CustomerSupportRequesterController.createContactForClient(wrapper.firstName, wrapper.lastName, wrapper.email);
                        update searchedClients[0];
                    }
                    // in the end we send email
                    CustomerSupportRequesterController.sendEmailSupportRequestCreated(searchedClients[0].Related_Contact__c, relatedCaseId);
                    return 'CREATED';
                }
                // Client has Case related, check for Contact and create if not existent, then send email that customer request already open
                else {
                    if (searchedClients[0].Related_Contact__c == null){
                        searchedClients[0].Related_Contact__c = CustomerSupportRequesterController.createContactForClient(wrapper.firstName, wrapper.lastName, wrapper.email);
                        update searchedClients[0];
                    }
                    CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(searchedClients[0].Related_Contact__c, searchedClients[0].Related_Case__c);
                    return 'ALREADY_OPEN';
                }
            }
            // no Client match found, fallback to Contacts
            if (searchedClients.size() == 0){
                List<Contact> searchedContacts = [SELECT Id, FirstName, LastName, Email, Related_Case__c
                                                FROM Contact
                                                WHERE FirstName =: wrapper.firstName
                                                AND Email =: wrapper.email];

                // perfect Contact match, look for Case
                if (searchedContacts.size() == 1){
                    // if no Case related, create one from wrapper data
                    if (searchedContacts[0].Related_Case__c == null){
                        Id relatedCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToContact(searchedContacts[0], wrapper.description);
                        CustomerSupportRequesterController.sendEmailSupportRequestCreated(searchedContacts[0].Id, relatedCaseId);
                        return 'CREATED';
                    }
                    // Client has Case related, throw error  
                    else {
                        CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(searchedContacts[0].Id, searchedContacts[0].Related_Case__c);
                        return 'ALREADY_OPEN';
                    }
                }

                // no Contact match found, throw error
                if (searchedContacts.size() == 0){
                    CustomerSupportRequesterController.sendGuestEmailNoMatchFound(wrapper.email); 
                    return 'NOT_FOUND';
                }

                // error, multiple Contacts matched
                if (searchedContacts.size() > 1) {
                    throw new AuraHandledException('Multiple contact records matched, which should not possible, please contact the Support Team!');
                }
            }
        }   

        if (wrapper.lastName == null){
            String searchName = wrapper.firstName + '%';
            String placeholderLastName = 'Unknown';

            List<Client__c> searchedClients = [SELECT Id, Name, Email_Address__c, Related_Case__c, Related_Contact__c
                                            FROM Client__c 
                                            WHERE Name LIKE :searchName
                                            AND Email_Address__c = :wrapper.email];


            // perfect match with Client, check for Case
            if (searchedClients.size() == 1){
                // if no Case related, create from wrapper data and relate to Client
                if (searchedClients[0].Related_Case__c == null){
                    Id relatedCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToClient(searchedClients[0], wrapper.description);
                    // we need a Contact in order to send an Email with according Case data
                    // so that if the matching Client doesn't have a Contact related, we create one and relate it
                    if (searchedClients[0].Related_Contact__c == null){
                        searchedClients[0].Related_Contact__c = CustomerSupportRequesterController.createContactForClient(wrapper.firstName, wrapper.lastName, wrapper.email);
                        update searchedClients[0];
                    }
                    // in the end we send email
                    CustomerSupportRequesterController.sendEmailSupportRequestCreated(searchedClients[0].Related_Contact__c, relatedCaseId);
                    return 'CREATED';
                }
                // if Case already related check for Contact and create if not existent, then send email that customer request already open
                else {
                    if (searchedClients[0].Related_Contact__c == null){
                        searchedClients[0].Related_Contact__c = CustomerSupportRequesterController.createContactForClient(wrapper.firstName, placeholderLastName, wrapper.email);
                        update searchedClients[0];
                    }
                    CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(searchedClients[0].Related_Contact__c, searchedClients[0].Related_Case__c);
                    return 'ALREADY_OPEN';
                }
            }
            
            // if no matches, filter only by email
            if (searchedClients.size() == 0) {
                List<Client__c> searchedClientsEmailOnly = [SELECT Id, Name, Email_Address__c, Related_Case__c, Related_Contact__c
                                                            FROM Client__c 
                                                            WHERE Email_Address__c = :wrapper.email];
                // if perfect match found by email only, check for Case
                if (searchedClientsEmailOnly.size() == 1){
                    // create if not existing
                    if (searchedClientsEmailOnly[0].Related_Case__c == null){
                        Id relatedCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToClient(searchedClientsEmailOnly[0], wrapper.description);
                        // we need a Contact in order to send an Email with according Case data
                        // so that if the matching Client doesn't have a Contact related, we create one and relate it
                        if (searchedClientsEmailOnly[0].Related_Contact__c == null){
                            searchedClientsEmailOnly[0].Related_Contact__c = CustomerSupportRequesterController.createContactForClient(wrapper.firstName, wrapper.lastName, wrapper.email);
                            update searchedClientsEmailOnly[0];
                        }
                        // in the end we send email
                        CustomerSupportRequesterController.sendEmailSupportRequestCreated(searchedClientsEmailOnly[0].Related_Contact__c, relatedCaseId);
                        return 'CREATED';
                    }
                    else {
                        if (searchedClientsEmailOnly[0].Related_Contact__c == null){
                            searchedClientsEmailOnly[0].Related_Contact__c = CustomerSupportRequesterController.createContactForClient(wrapper.firstName, placeholderLastName, wrapper.email);
                            update searchedClientsEmailOnly[0];
                        }
                        CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(searchedClientsEmailOnly[0].Related_Contact__c, searchedClientsEmailOnly[0].Related_Case__c);
                        return 'ALREADY_OPEN';
                    }
                }

                if (searchedClientsEmailOnly.size() == 0){
                    // fallback to Contacts (has Email field)
                    List<Contact> searchedContacts = [SELECT Id, FirstName, LastName, Related_Case__c
                                                    FROM Contact
                                                    WHERE FirstName =: wrapper.firstName
                                                    AND LastName =: wrapper.lastName
                                                    AND Email =: wrapper.email];
            
                    // Contact perfect match found, check for related Case
                    if (searchedContacts.size() == 1){
                        // no related Case, create one with wrapper data
                        if (searchedContacts[0].Related_Case__c == null){
                            Id relatedCaseId = CustomerSupportRequesterController.createNewCaseAndRelateToContact(searchedContacts[0], wrapper.description);
                            CustomerSupportRequesterController.sendEmailSupportRequestCreated(searchedContacts[0].Id, relatedCaseId);
                        }
                        // if Case already related, throw error
                        else {
                            CustomerSupportRequesterController.sendEmailSupportRequestAlreadyOpen(searchedContacts[0].Id, searchedContacts[0].Related_Case__c);
                            return 'ALREADY_OPEN';
                        }
                    }

                    // not even Contact match found, throw error
                    if (searchedContacts.size() == 0){
                        CustomerSupportRequesterController.sendGuestEmailNoMatchFound(wrapper.email);
                        return 'NOT_FOUND';
                    }

                    // multiple Contacts found, no perfect match
                    if (searchedContacts.size() > 1){
                        throw new AuraHandledException('Multiple contact records matched, which should not possible, please contact the Support Team!');
                    }
                }

                if (searchedClientsEmailOnly.size() > 1){
                    throw new AuraHandledException('Multiple client records matched, which should not possible, please contact the Support Team!');
                }
            }

            if (searchedClients.size() > 1){
                throw new AuraHandledException('Multiple client records matched, which should not possible, please contact the Support Team!');
            }
            
        }

        return null;     
    }

    public static Id createNewCaseAndRelateToClient(Client__c client, String description){
        Case newCase = new Case();

        String caseSubject = client.Name + ' - ' + client.Email_Address__c;

        newCase.Subject = caseSubject;
        newCase.Status = 'New';
        newCase.Origin = 'Web';
        newCase.Description = description;
        // email templates are dumb, cannot work with strings in the editor, need each one individual 
        newCase.SuppliedName = client.Name;           
        newCase.SuppliedEmail = client.Email_Address__c;

        insert newCase;

        client.Related_Case__c = newCase.Id;

        update client;

        return newCase.Id;
    }

    public static Id createNewCaseAndRelateToContact(Contact con, String description){
        Case newCase = new Case();
    
        String caseSubject = con.FirstName + ' ' + con.LastName + ' - ' + con.Email;
    
        newCase.Subject = caseSubject;
        newCase.Status = 'New';
        newCase.Origin = 'Web';
        newCase.Description = description;
        // email templates are dumb, cannot work with strings in the editor, need each one individual 
        newCase.SuppliedName = con.FirstName + ' ' + con.LastName;           
        newCase.SuppliedEmail = con.Email;
    
        insert newCase;
    
        con.Related_Case__c = newCase.Id;
    
        update con;

        return newCase.Id;
    }

    public static void sendGuestEmailNoMatchFound(String recipientEmail){
        EmailTemplate et = [SELECT Id, Subject, HtmlValue, Body, DeveloperName
                            FROM EmailTemplate
                            WHERE DeveloperName = 'Client_Not_Found_1774354497558'];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] { recipientEmail });
    
        mail.setSubject(et.Subject);
        mail.setHtmlBody(et.HtmlValue); 
        mail.setPlainTextBody(et.Body); 

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static void sendEmailSupportRequestAlreadyOpen(Id recipientId, Id caseId){
        EmailTemplate et = [SELECT Id, Subject, HtmlValue, Body, DeveloperName
                            FROM EmailTemplate
                            WHERE DeveloperName = 'Client_Found_Customer_Support_Request_Already_In_Process_1774353180578'];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setTargetObjectId(recipientId); 
        mail.setWhatId(caseId); 
        mail.setTemplateId(et.Id);
        mail.setSaveAsActivity(true);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static void sendEmailSupportRequestCreated(Id recipientId, Id caseId){
        EmailTemplate et = [SELECT Id, Subject, HtmlValue, Body, DeveloperName
                            FROM EmailTemplate
                            WHERE DeveloperName = 'Client_Found_1774350650634'];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setTargetObjectId(recipientId); 
        mail.setWhatId(caseId); 
        mail.setTemplateId(et.Id);
        mail.setSaveAsActivity(true);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static Id createContactForClient(String firstName, String lastName, String email){
        Contact newContact = new Contact(
            FirstName = firstName, 
            LastName = lastName,
            Email = email);

        insert newContact;

        return newContact.Id;
    }
}
