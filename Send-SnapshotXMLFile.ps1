<#
.SYNOPSIS
  Submits a Snapshot XML File to Blackboard Learn for Processing
.DESCRIPTION
  Submits an XML feed file to a Snapshot XML File Student Information System Integraion on Blackboard Learn for processing, and returns a Data Set UID that can be used to monitor the status of the submitted feed file
.EXAMPLE
  Send-SnapshotXMLFile -Server "blackboard.monument.edu" -OperationType RecordStatus -IntegrationUsername "01928374-5647-4abc-faeb-0156924783af" -IntegrationPassword "thisisnotagoodpassword" -FeedFile D:\path_to_feed_file.xml
.EXAMPLE
  Send-SnapshotXMLFile -Server "blackboard.monument.edu" --OperationType DeleteOnly -IntegrationUsername "01928374-5647-4abc-faeb-0156924783af" -IntegrationPassword "thisisnotagoodpassword" -FeedString "<enterprise><group><sourcedid><source>Purge</source><id>DELTE_THIS_COURSE</id></sourcedid></group></enterprise>"
.PARAMETER Server
  The address of the server to send the feed file to. Could be a hostname, fully-quallified domain name, or IP address.
.PARAMETER OperationType
  Specifies the type of operation to perform.

  Valid Options are:
  - RecordStatus
  - CompleteRefresh
  - CompleteRefreshByDataSource
  - DeleteOnly
.PARAMETER IntegrationUsername
  The username defined in the SIS Integration Configuration in Blackboard
.PARAMETER IntegrationPassword
  The coresponding password defined in the SIS Integration Configuration in Blackbaord
.PARAMETER FeedString
  The "Feed File" to send. This should be a string, not a path to a file.

  Use this for programatically generated Feed Files you don't want to save to the filesystem.
.PARAMETER FeedFile
  The Feed File to send. This should be a path to a file.
.PARAMETER Port
  Non-standard (i.e. other than 443 for HTTPS or 80 for HTTP) port used to connect to Blackboard
.PARAMETER UseHTTP
  Use HTTP rather than the default of HTTPS
.PARAMETER IgnoreCertificateErrors
  Ignore certificate errors, e.g. if using self-signed certificates when uploading directly to an app server
#>
function Send-SnapshotXMLFile
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                   PositionalBinding=$false)]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        [Parameter(Mandatory=$true)]
        [ValidateSet("RecordStatus", "CompleteRefresh", "CompleteRefreshByDataSource", "DeleteOnly")]
        [String]
        $OperationType,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IntegrationUsername,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $IntegrationPassword,

        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='FeedFile')]
        [ValidateNotNullOrEmpty()]
        [String]
        $FeedFile,

        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='FeedString')]
        [ValidateNotNullOrEmpty()]
        [String]
        $FeedString,

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
        
        # Build the Upload URI based on the options specified

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

        $URIBase = "/webapps/bb-data-integration-ss-xml-BBLEARN/endpoint"

        switch ( $OperationType ) {
          "RecordStatus" { $URIOperation = ""; break }
          "CompleteRefresh" { $URIOperation = "/refresh"; break }
          "CompleteRefreshByDataSource" { $URIOperation = "/refreshlegacy"; break }
          "DeleteOnly" { $URIOperation = "/delete"; break }
        }


        $URI = $URIProtocol+$URIServer+$URIPort+$URIBase+$URIOperation

        # Build the PSCredential object to be used 

        $securePassword = ConvertTo-SecureString $IntegrationPassword -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential($IntegrationUsername,$securePassword)

        if ($IgnoreCertificateErrors)
        {
            Set-StrictMode -Version 2

            # You have already run this function
            if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -eq 'IgnoreCerts') { Return }

            $Domain = [AppDomain]::CurrentDomain
            $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
            $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
            $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
            $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
            $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
            $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | % {$_.ParameterType})))
            $ILGen = $MethodBuilder.GetILGenerator()
            $ILGen.Emit([Reflection.Emit.Opcodes]::Ldc_I4_1)
            $ILGen.Emit([Reflection.Emit.Opcodes]::Ret)
            $TypeBuilder.CreateType() | Out-Null

            # Disable SSL certificate validation
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object IgnoreCerts
        }

        # If using a Feed File, rather than a Feed String, Verify that it actually exists
        if ( $pscmdlet.ParameterSetName -eq "FeedFile" )
        {
            if ( -not (Test-Path $FeedFile) )
            {
                throw [System.IO.FileNotFoundException] "$($FeedFile) not found."
            }
        }

        if ( $pscmdlet.ShouldProcess( $Server, "Upload Feed File" ) )
        {

            if ( $pscmdlet.ParameterSetName -eq "FeedFile" )
            {
               try
               {
                   $uploadResponse = Invoke-RestMethod -Uri $URI -Credential $credentials -ContentType "text/plain" -Method Post -InFile $FeedFile
               }
               catch
               {
                   $exception = $_.Exception.ToString()
                   throw "There was an error uploading the Feed File: $($exception)"
               }
            }
            else
            {
                try
               {
                   $uploadResponse = Invoke-RestMethod -Uri $URI -Credential $credentials -ContentType "text/plain" -Method Post -Body $FeedString
               }
               catch
               {
                   $exception = $_.Exception.ToString()
                   throw "There was an error uploading the Feed File: $($exception)"
               }
            }

            try
            {
                # The Data Set UID is the 9th "word" in the response for an upload
                $words = $uploadResponse.split()
                $statusID = $words[9]
                return $statusID
            }
            catch
            {
                $exception = $_.Exception.ToString()
                throw "There was an error getting the Data Set ID from the feed file response: $($exception)"
            }
        }

       
    }
    End
    {
    }
}
