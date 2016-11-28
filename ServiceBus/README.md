# Azure Service Bus Monitoring

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftianderturpijn%2FOMS%2Fmaster%2FServiceBus%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This solution (currently in private preview) will allow you to capture your Azure Service Bus metrics and visualize them in Operations Management Suite (Log Analytics). This solution leverages an automation runbook in Azure Automation, the Log Analytics Ingestion API, together with Log Analytics views to present data about all your Azure Service Bus instances in a single log analytics workspace. 

## Prerequisites

+ Azure Subscription (if you don’t have one you can create one [here](https://azure.microsoft.com/en-us/free/))
+ Operations Management Suite Account (Free Sign Up – No credit card required. Sign up for your free OMS account [here](https://www.microsoft.com/en-us/cloud-platform/operations-management-suite))
+ **New Azure Automation Account (with RunAs Account). To create a new Automation Account refer to step 4 below.**

## How do I get started?

1. **Create a new Automation account**: Go back into the Azure Portal https://portal.azure.com opening a separate tab from the one that is already opened with the ARM Template. * If you have an existing OMS Log Analytics workspace in a Resource Group, proceed to create the Automation account in this Resource Group. It is recommended that the Azure region is the same as the OMS Log Analytics resource. By default, the wizard will create an SPN account as part of this process. Note: Make sure to create the new Automation Account leveraged for this solution in the subscription that you are wanting to monitor the Azure Service Bus instances. * If you don’t have an existing OMS Log Analytics workspace in a Resource Group, create a new Automation account into a new Resource Group. SPN account will be created by default.

2. Click the button that says ‘**Deploy to Azure**’. This will launch the ARM Template you need to configure in the Azure Portal.
  
3. You need to provide the OMS Workspace ID, OMS Workspace Key, Automation Account Name, and Automation Region in the custom deployment ARM template.

