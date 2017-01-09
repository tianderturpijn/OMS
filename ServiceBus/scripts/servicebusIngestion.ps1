﻿# Suspend the runbook if any errors, not just exceptions, are encountered
$ErrorActionPreference = "Stop"

# ASM authentication
$ConnectionAssetName = "AzureClassicRunAsConnection"

# Get the connection
$connection = Get-AutomationConnection -Name $connectionAssetName        

# Authenticate to Azure with certificate
Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
$Conn = Get-AutomationConnection -Name $ConnectionAssetName
if ($Conn -eq $null)
{
    throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
}

$CertificateAssetName = $Conn.CertificateAssetName
Write-Verbose "Getting the certificate: $CertificateAssetName" -Verbose
$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
if ($AzureCert -eq $null)
{
    throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
}

Write-Verbose "Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert 
Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID
#endregion

# Variables definition
# Starttime for gathering DB metrics (default is 5 minutes in the past) and run every 10 mins on a schedule for 2 metric points per run 
$StartTime = [dateTime]::Now.Subtract([TimeSpan]::FromMinutes(5))

#Replace the below string with a metric value name such as 'TimeStamp' to update TimeGenerated to be that metric named instead of ingestion time
$Timestampfield = "Timestamp" 

#Update customer Id to your Operational Insights workspace ID
$customerID = Get-AutomationVariable -Name 'OMSWorkspaceId'

#For shared key use either the primary or seconday Connected Sources client authentication key   
$sharedKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'


#Start Script (MAIN)
#Login to Azure account and select the subscription.

#Authenticate to Azure with SPN section
"Logging in to Azure..."
$Conn = Get-AutomationConnection -Name AzureRunAsConnection 
 Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID `
 -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

"Selecting Azure subscription..."
$SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid 

# Define Log Type 
$logType  = "servicebus"
"Logtype Name for ServiceBus(es) is '$logType'"

　
	$sbList = Get-AzureSBNamespace
	if ($sbList -ne $null)
	{
		"Found $($sbList.Count) service bus namespace(s)."
		
		foreach ($sb in $sbList)
		{
		    # Format metrics into a table.
		    $table1 = @()
            $table2 = @()
		    
			"Processing service bus `"$($sb.Name)`"..."
			    
		    $sbAuth = Get-AzureSBAuthorizationRule -Namespace $sb.Name
		    $nsManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($sbAuth.ConnectionString);

#call Function queues here
#GetAndPublishQueues


            "Attempting to get queues...."
		    $queueList = $nsManager.GetQueues()

#region ForEach sqQueue
		    foreach ($sbQueue in $queueList)
		    {
				#$sbQueue
				#"Processing queue $($sbQueue.Name)..."
					
				$Queue = $null
				try
				{
		        	$Queue = $nsManager.GetQueue($sbQueue.Path);
				}
				catch [exception]
				{
					"Unable to get queue for '$($sbQueue)': $_"
				}

				
				if ($Queue -ne $null)
				{
			        $sx = New-Object PSObject -Property @{
			            #Timestamp = $([DateTime]::Now.ToString());
						TimeStamp = $([DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"));
			            SubscriptionName = $subscriptionName;
                        ServiceBusName = $sb.Name;
                        Region = $sb.Region;
                        NamespaceType = $sb.Namespacetype.ToString();
                        ConnectionString = $sb.connectionString;
			
			            <#
			            ## Standard SB Message Properties
			            
			            LockDuration = $Queue.LockDuration;
			            MaxSizeInMegabytes = $Queue.MaxSizeInMegabytes;
			            RequiresDuplicateDetection = $Queue.RequiresDuplicateDetection;
			            RequiresSession = $Queue.RequiresSession;
			            DefaultMessageTimeToLive = $Queue.DefaultMessageTimeToLive;
			            AutoDeleteOnIdle = $Queue.AutoDeleteOnIdle;
			            EnableDeadLetteringOnMessageExpiration = $Queue.EnableDeadLetteringOnMessageExpiration;
			            DuplicateDetectionHistoryTimeWindow = $Queue.DuplicateDetectionHistoryTimeWindow;
			            Path = $Queue.Path;
			            MaxDeliveryCount = $Queue.MaxDeliveryCount;
			            EnableBatchedOperations = $Queue.EnableBatchedOperations;
			            SizeInBytes = $Queue.SizeInBytes;
			            MessageCount = $Queue.MessageCount;
			
			            #MessageCountDetails = $Queue.MessageCountDetails;
			            ActiveMessageCount = $Queue.MessageCountDetails.ActiveMessageCount;
			            DeadLetterMessageCount = $Queue.MessageCountDetails.DeadLetterMessageCount;
			            ScheduledMessageCount = $Queue.MessageCountDetails.ScheduledMessageCount;
			            TransferMessageCount = $Queue.MessageCountDetails.TransferMessageCount;
			            TransferDeadLetterMessageCount = $Queue.MessageCountDetails.TransferDeadLetterMessageCount;
			
			            Authorization = $Queue.Authorization;
			            IsAnonymousAccessible = $Queue.IsAnonymousAccessible;
			            SupportOrdering = $Queue.SupportOrdering;
			            Status = $Queue.Status;
			            AvailabilityStatus = $Queue.AvailabilityStatus;
			            ForwardTo = $Queue.ForwardTo;
			            ForwardDeadLetteredMessagesTo = $Queue.ForwardDeadLetteredMessagesTo;
			            CreatedAt = $Queue.CreatedAt;
			            UpdatedAt = $Queue.UpdatedAt;
			            AccessedAt = $Queue.AccessedAt;
			            EnablePartitioning = $Queue.EnablePartitioning;
			            UserMetadata = $Queue.UserMetadata;
			            EnableExpress = $Queue.EnableExpress;
			            IsReadOnly = $Queue.IsReadOnly;
			            ExtensionData = $Queue.ExtensionData;
			            
			            ##
			            #>
			
			            <# SB Message properties we care about #>
			            Path = $Queue.Path;
			            MaxDeliveryCount = $Queue.MaxDeliveryCount;
			            SizeInBytes = $Queue.SizeInBytes;
			            MessageCount = $Queue.MessageCount;
			
			            ActiveMessageCount = $Queue.MessageCountDetails.ActiveMessageCount;
			            DeadLetterMessageCount = $Queue.MessageCountDetails.DeadLetterMessageCount;
			            ScheduledMessageCount = $Queue.MessageCountDetails.ScheduledMessageCount;
			            TransferMessageCount = $Queue.MessageCountDetails.TransferMessageCount;
			            TransferDeadLetterMessageCount = $Queue.MessageCountDetails.TransferDeadLetterMessageCount;
			
			            Status = $Queue.Status;
			            AvailabilityStatus = $Queue.AvailabilityStatus;            
			            CreatedAt = $Queue.CreatedAt;
			            UpdatedAt = $Queue.UpdatedAt;
			            AccessedAt = $Queue.AccessedAt;
			        }
			
					$sx
					
			        $table1 = $table1 += $sx
			        
			        # Convert table to a JSON document for ingestion 
			        $jsonTable = ConvertTo-Json -InputObject $table
				}
			    #Post the data to the endpoint - looking for an "accepted" response code 
		    	#Send-OMSAPIIngestionData -customerId $customerId -sharedKey $sharedKey -body $jsonTable -logType $logType -TimeStampField $Timestampfield
		    	# Uncomment below to troubleshoot
		    	$jsonTable
			}
#endregion



#call Function topics here
#GetAndPublishTopics



<# error handling topics       
                "Attempting to get topics..."
            	$topicList = $null
				try
				{
		        	$topicList = $nsManager.GetTopics();
				}
				catch [exception]
				{
					"Unable to get topics, no topics found or something went wrong"
				}
#>
#region ForEach Topics
    		foreach ($topic in $topicList)
		    {
				
				if ($topicList -ne $null)
				{
			        $sx2 = New-Object PSObject -Property @{
						TimeStamp = $([DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"));
                        TopicName = $topic.path;			            

			        }
			
					$sx2
					
			        $table2 = $table2 += $sx2
			        
			        # Convert table to a JSON document for ingestion 
			        $jsonTable = ConvertTo-Json -InputObject $table2
				}
			    #Post the data to the endpoint - looking for an "accepted" response code 
		    	#Send-OMSAPIIngestionData -customerId $customerId -sharedKey $sharedKey -body $jsonTable -logType $logType -TimeStampField $Timestampfield
		    	# Uncomment below to troubleshoot
		    	$jsonTable
			}
#endregion

		}
	} else
	{
		"This subscription contains no service bus namespaces."
	}


　
<#
foreach ($sub in $subscriptionList)
{
	"Processing subscription $($sub.SubscriptionId) `"$($sub.SubscriptionName)`"..."
		
	Publish-SBMetrics -azureSubscriptionID $sub.SubscriptionId	
			
}

"Done processing all subscriptions."
 
#>

<#
                        #RequiresDuplicateDetection = $topic.RequiresDuplicateDetection

                        #ConnectionString = $sb.connectionString;
                        #DefaultMessageTimeToLive = $topic.DefaultMessageTimeToLive
                        #AutoDeleteOnIdle = $topic.AutoDeleteOnIdle
                        #MaxSizeInMegabytes = $topic.MaxSizeInMegabytes
                        #DuplicateDetectionHistoryTimeWindow = $topic.DuplicateDetectionHistoryTimeWindow
                        #SizeInBytes = $topic.SizeInBytes
                        #EnableBatchedOperations = $topic.EnableBatchedOperations
                        #SupportOrdering = $topic.SupportOrdering
                        #EnableFilteringMessagesBeforePublishing = $topic.EnableFilteringMessagesBeforePublishing
                        #IsAnonymousAccessible = $topic.IsAnonymousAccessible
                        #Status = $topic.Status
                        #AvailabilityStatus = $topic.AvailabilityStatus
                        #CreatedAt = $topic.CreatedAt
                        #UpdatedAt = $topic.UpdatedAt
                        #AccessedAt = $topic.AccessedAt
                        #SubscriptionCount = $topic.SubscriptionCount
                        #EnablePartitioning = $topic.EnablePartitioning
                        #EnableExpress = $topic.EnableExpress
                        #IsReadOnly = $topic.IsReadOnly
#>
 

