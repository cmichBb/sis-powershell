<#
.SYNOPSIS
  Gets the status of a submitted feed file
.DESCRIPTION
  Gets the status of a submitted feed file based on its Data Set ID
.EXAMPLE
  Get-FeedFileStatus -Server "blackboard.monument.edu" -IntegrationType SnapshotFlatFile -IntegrationUsername "01928374-5647-4abc-faeb-0156924783af" -IntegrationPassword "thisisnotagoodpassword" -DataSetUID "b80f07b065ce404abeda343b17605355"
.PARAMETER Server
  The address of the server to send the feed file to. Could be a hostname, fully-quallified domain name, or IP address.
.PARAMETER IntegrationType
  Specifies the type of integration the feed file was submitted to.

  Valid options are:
  - SnapshotFlatFile
  - SnapshotXML
  - LISDraft
  - LISFinal
.PARAMETER IntegrationUsername
  The username defined in the SIS Integration Configuration in Blackboard
.PARAMETER IntegrationPassword
  The coresponding password defined in the SIS Integration Configuration in Blackbaord
.PARAMETER DataSetUID
  The Data Set UID returned by Learn when the feed file was submitted to the SIS Integration
.PARAMETER Summary
  Returns a summary of the status of this data set, including start time, last action time, and complete, error, warning, and queued record counts
.PARAMETER Complete
  Returns the complete record count for this data set
.PARAMETER Error
  Returns the error record count for this data set
.PARAMETER Warning
  Returns the warning record count for this data set
.PARAMETER Queued
  Returns the queued record count for this data set (Author's Note: I've never seen this be useful. It's always either 1 or 0.)
.PARAMETER Port
  Non-standard (i.e. other than 443 for HTTPS or 80 for HTTP) port used to connect to Blackboard
.PARAMETER UseHTTP
  Use HTTP rather than the default of HTTPS
.PARAMETER IgnoreCertificateErrors
  Ignore certificate errors, e.g. if using self-signed certificates when uploading directly to an app server
#>
function Get-FeedFileStatus
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                   PositionalBinding=$false,
                   DefaultParameterSetName="Summary")]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        [Parameter(Mandatory=$true)]
        [ValidateSet("SnapshotFlatFile", "SnapshotXML", "LISDraft", "LISFinal")]
        [String]
        $IntegrationType,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IntegrationUsername,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IntegrationPassword,

        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DataSetUID,

        [Parameter(ParameterSetName='Summary')]
        [Switch]
        $Summary,

        [Parameter(ParameterSetName='Complete')]
        [Switch]
        $Complete,

        [Parameter(ParameterSetName='Error')]
        [Switch]
        $Error,

        [Parameter(ParameterSetName='Warning')]
        [Switch]
        $Warning,

        [Parameter(ParameterSetName='Queued')]
        [Switch]
        $Queued,

        [int]
        $Port = 0,

        [Switch]
        $UseHTTP,

        [Switch]
        $IgnoreCertificateErrors
    )

    Begin
    {
    }
    Process
    {
        # Build the status check URI based on the options specified
        
        if ( $UseHTTP ) {
            $URIProtocol = "http://"
        } else {
            $URIProtocol = "https://"
        }

        $URIServer = $Server

        if ( $Port -eq 0 ) {
            $URIPort = ""
        } else {
            $URIPort = ":"+$Port
        }

        if ( $IntegrationType -eq "SnapshotFlatFile" ) {
            $URIBase = "/webapps/bb-data-integration-flatfile-BBLEARN/endpoint/dataSetStatus/"
        }
        elseif ( $IntegrationType -eq "SnapshotXML" ) {
            $URIBase = "/webapps/bb-data-integration-ss-xml-BBLEARN/endpoint/dataSetStatus/"
        }
        

        $URI = $URIProtocol+$URIServer+$URIPort+$URIBase+$DataSetUID

        # Build the PSCredential object to be used 

        $securePassword = ConvertTo-SecureString $IntegrationPassword -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential($IntegrationUsername,$securePassword)
        
        if ($pscmdlet.ShouldProcess($DataSetUID, "Check Data Set Status"))
        {
            try
            {
                $statusResponse = Invoke-RestMethod -Uri $URI -Credential $credentials -ContentType "text/plain" -Method Get
                $xmlResponse = [xml]($statusResponse)

                if ($Complete)
                {
                    return $xmlResponse.dataSetStatus.completedCount
                }
                elseif ($Warning)
                {
                    return $xmlResponse.dataSetStatus.warningCount
                }
                elseif ($Error)
                {
                    return $xmlResponse.dataSetStatus.errorCount
                }
                elseif ($Queued)
                {
                    return $xmlResponse.dataSetStatus.queuedCount
                }
                else
                {
                    $theSummary = "Data Set Summary for: $($DataSetUID)`r`nCompleted Records: $($xmlResponse.dataSetStatus.completedCount)`r`nError Records: $($xmlResponse.dataSetStatus.errorCount)`r`nWarning Records: $($xmlResponse.dataSetStatus.warningCount)`r`nQueued Records: $($xmlResponse.dataSetStatus.queuedCount)`r`nStart Date: $($xmlResponse.dataSetStatus.startDate)`r`nLast Entry Date: $($xmlResponse.dataSetStatus.lastEntryDate)"
                    return $theSummary
                }
            }
            catch
            {
                throw "Could not retrieve data set status for Data Set ID $($DataSetUID)"
            }

        }
    }
    End
    {
    }
}