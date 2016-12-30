#Version 0.2 for Azure Service Bus monitoring
# Suspend the runbook if any errors, not just exceptions, are encountered
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

$logType  = "servicebus"
"Logtype Name for ServiceBus(es) is '$logType'"

Function Publish-SbQueueMetrics{
$sbList = Get-AzureSBNamespace
	if ($sbList -ne $null)
	{
		"Found $($sbList.Count) service bus namespace(s)."
		
		foreach ($sb in $sbList)
		{
		    # Format metrics into a table.
		    $table1 = @()
		    
			"Processing service bus `"$($sb.Name)`" for queues..."
			    
		    $sbAuth = Get-AzureSBAuthorizationRule -Namespace $sb.Name
		    $nsManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($sbAuth.ConnectionString);

            "Attempting to get queues...."
		    $queueList = $nsManager.GetQueues()

		    foreach ($sbQueue in $queueList)
		    {
					
				$Queue = $null
				try
				{
		        	$Queue = $nsManager.GetQueue($sbQueue.Path);
				}
                
                catch
                {
                "Could not get any queues"
                $ErrorMessage = $_.Exception.Message
                Write-Output ("Error Message: " + $ErrorMessage)
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
			        $jsonTable1 = ConvertTo-Json -InputObject $table1
				}
			    #Post the data to the endpoint - looking for an "accepted" response code 
		    	Send-OMSAPIIngestionData -customerId $customerId -sharedKey $sharedKey -body $jsonTable1 -logType $logType -TimeStampField $Timestampfield
		    	# Uncomment below to troubleshoot
		    	#$jsonTable
			}
		}
	} 
    else
	{
		"This subscription contains no service bus namespaces."
	}
}

Function Publish-SbTopicMetrics{
$sbList = Get-AzureSBNamespace
	if ($sbList -ne $null)
	{
		#"Found $($sbList.Count) service bus namespace(s)."
		
		foreach ($sb in $sbList)
		{
		    # Format metrics into a table.
            $table2 = @()
		    $jsonTable2 = @()
			
            "Processing service bus `"$($sb.Name)`" for Topics..."
			    
		    $sbAuth = Get-AzureSBAuthorizationRule -Namespace $sb.Name
		    $nsManager = [Microsoft.ServiceBus.NamespaceManager]::CreateFromConnectionString($sbAuth.ConnectionString);

            #Topics section
            "Attempting to get topics...."
            $topicList = @()

            try
            {
                $topicList = $nsManager.GetTopics()
            }
            catch
            {
                "Could not get any topics"
                $ErrorMessage = $_.Exception.Message
                Write-Output ("Error Message: " + $ErrorMessage)
            }
            
            "Found $($topicList.path.count) topic(s)."
            foreach ($topic in $topicList)
		    {
				if ($topicList -ne $null)
				{
			        $sx2 = New-Object PSObject -Property @{
                        TimeStamp = $([DateTime]::Now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"));
                        TopicName = $topic.path;
                        MaxSizeInMegabytes = $topic.MaxSizeInMegabytes;
                        SizeInBytes = $topic.SizeInBytes;
                        Status = $topic.Status;
                        AvailabilityStatus = $topic.AvailabilityStatus;
                        
			        }
			
					$sx2
			        $table2 = $table2 += $sx2
			        
			        # Convert table to a JSON document for ingestion 
			        $jsonTable2 = ConvertTo-Json -InputObject $table2
				}
                else{"No topics found."}
		    	Send-OMSAPIIngestionData -customerId $customerId -sharedKey $sharedKey -body $jsonTable2 -logType $logType -TimeStampField $Timestampfield
		    	# Uncomment below to troubleshoot
		    	#$jsonTable
			}
		}
	} 
    else
	{
		"This subscription contains no service bus namespaces."
	}
}

$output1 = Publish-SbQueueMetrics
$output1
$output2 = Publish-SbTopicMetrics
$output2
