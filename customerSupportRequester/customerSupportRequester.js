// customerSupportRequester.js
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import processCustomerSupportRequest from '@salesforce/apex/CustomerSupportRequesterController.processCustomerSupportRequest';

export default class CustomerSupportRequester extends LightningElement {
    lastName;
    firstName;
    emailAddress;
    incidentDescription;

    isStarted = false;
    isDataGathered = true;
    isLoading = false;

    handleLastNameChange(event){
        this.lastName = event.target.value; 
    }

    handleFirstNameChange(event){
        this.firstName = event.target.value;
    }

    handleEmailAddressChange(event){
        this.emailAddress = event.target.value;
    }

    handleIncidentDescriptionChange(event){
        this.incidentDescription = event.target.value;
    }

    startCustomerSupportRequest(){
        this.isStarted = true;
    }

    async sendCustomerSupportRequest(){
        if (!this.firstName || !this.emailAddress || !this.incidentDescription) {
            this.showErrorToast('Please fill in all required fields.');
            return;
        }

        const wrapper = {
            lastName: this.lastName,
            firstName: this.firstName,
            email: this.emailAddress,
            description: this.incidentDescription
        };
        
        this.isLoading = true;
        try {
            const status = await processCustomerSupportRequest({ wrapper });

            if (status === 'CREATED') {
                this.showSuccessToast('Your Customer Support Request has been created!');
            } else if (status === 'ALREADY_OPEN') {
                this.showErrorToast('You already have an ongoing request — it cannot be duplicated until resolved.');
            } else if (status === 'NOT_FOUND') {
                this.showErrorToast('No match found for the credentials inputted, please try again!');
            }

            this.exitLWC();
        } catch (error) {
            this.showErrorToast(error.body?.message);
        } finally {
            this.isLoading = false;
        }
    } 

    exitLWC(){
        this.lastName = null;
        this.firstName = null;
        this.emailAddress = null;
        this.incidentDescription = null;
        this.isStarted = false;
        this.isDataGathered = false;
    }

    // 1. Success Toast (Green)
    showSuccessToast(msg) {
        const event = new ShowToastEvent({
            title: 'Success!',
            message: msg,
            variant: 'success',
            mode: 'sticky' 
        });
        this.dispatchEvent(event);
    }

    // 2. Error Toast (Red)
    showErrorToast(msg) {
        const event = new ShowToastEvent({
            title: 'Error occurred',
            message: msg,
            variant: 'error',
            mode: 'sticky' // Sticky keeps it visible until the user closes it
        });
        this.dispatchEvent(event);
    }
}
