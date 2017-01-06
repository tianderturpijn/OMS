
# Azure Service Bus Monitoring v0.2 - Test

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftianderturpijn%2FOMS%2Fmaster%2FServiceBusDev%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This solution (currently in private preview) will allow you to capture your Azure Service Bus metrics and visualize them in Operations Management Suite (Log Analytics). This solution leverages an automation runbook in Azure Automation, the Log Analytics Ingestion API, together with Log Analytics views to present data about all your Azure Service Bus instances in a single log analytics workspace. 

**Updates in this version:**
+ Added monitoring of Topics
+ Enabled removal of the view and solution in the Ibiza portal (under resource group properties)
+ Changed artifactsLocationSasToken to a variable instead of a parameter

## Prerequisites

+ Azure Subscription (if you don’t have one you can create one [here](https://azure.microsoft.com/en-us/free/))
+ Operations Management Suite Account (Free Sign Up – No credit card required. Sign up for your free OMS account [here](https://www.microsoft.com/en-us/cloud-platform/operations-management-suite))
+ New Azure Automation Account (with a RunAs Account AND a Classic RunAs account). To create a new Automation Account refer to step 1 below.
+ The schedule (which automatically will be created during deployment) to run the runbook requires a unique GUID, please run the PowerShell command "New-Guid" to generate one

**Note: The OMS Workspace and Azure Automation Account MUST exist within the same resource group. The Azure Automation Account name needs to be unique.**

## How do I get started?

1. **Create a new Automation account**: Go the Azure Portal https://portal.azure.com and create an Azure Automation account.

If you have an existing OMS Log Analytics workspace in a Resource Group, proceed to create the Automation account in this Resource Group. It is recommended that the Azure region is the same as the OMS Log Analytics resource. By default, the wizard will create an SPN account as part of this process.

Note: Make sure to create the new Automation Account leveraged for this solution in the subscription that you are wanting to monitor the Azure Service Bus instances. If you don’t have an existing OMS Log Analytics workspace in a Resource Group the template deployment will create one for you, create a new Automation account into a new Resource Group. A SPN account will be created by default.
**Note: An Azure Automation account needs to exist before deploying this solution, do not link it to your OMS workspace**

2. Click the button that says ‘**Deploy to Azure**’. This will launch the ARM Template you need to configure in the Azure Portal:

![alt text](images/step3deploy.png "Deployment in the portal")

  

**Deployment Settings**

1. Provide the name of the resource group name in which your new Azure Automation account resides (which you've created in step 1), **so select "Use existing"** . The resource group location will be automatiocally filled in.

2. Under "Settings" provide the name and the region of an existing OMS workspace. If you don't have an OMS workspace, the template deployment will create one for you.

3. Under "Oms Automation Account Name" provide the Automation Account name (which you've created in step 1) and the region where the Automation Account resides in.

4. Provide an unique Job Guid (this will be used to create a runbook schedule). You can generate a unique Job Guid in PowerShell like this:

![alt text](images/NewGuid.png "Generate a new GUID in PowerShell")

Accept the "Terms and Conditions" and click on "Purchase"

## Deploy using PowerShell:
````powershell
$myGUID = [guid]::newguid() 
New-AzureRmResourceGroupDeployment -name servicebus `
   -ResourceGroupName MyOMSRG `
   -TemplateFile 'https://raw.githubusercontent.com/tianderturpijn/OMS/master/ServiceBus/azuredeploy.json' `
   -omsWorkspaceName MyOMSworkspace `
   -omsAutomationAccountName MyAutomationAccountName `
   -workspaceRegion MyWorkspaceRegion `
   -automationRegion MyAutomationRegion `
   -jobGuid $myGUID `
   -verbose 
                                
````     
## Monitoring multiple subscriptions

The solution is designed to monitor Azure Service Bus instances across subscriptions.
To do so, you simply have to deploy this template and provide the workspace Id and the workspace Key for the workspace where you already have deployed the solution.

## Pre-reqs

- **Automation Account with SPN**

Due to specific dependencies to modules, variables and more, the solution requires that you creates additional Automation accounts when scaling the solution to collect data from multiple subscriptions. You must create an Automation Account in the Azure portal with the default settings so that the SPN account will be created.


- **OMS workspace Id and Key**

This template will have parameters that will ask for the workspace Id and the workspace Key, so that the runbooks are able to authenticate and ingest data.
You can log in to the OMS classic portal and navigate to Settings --> Connected Sources to find these values

Once you have completed the pre-reqs, you can click on the deploy button below

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftianderturpijn%2FOMS%2Fmaster%2FServiceBusDev%2FaddMultipleSubscriptions.json) 


Once deployed you should start to see data from your additional subscriptions flowing into your workspace.
