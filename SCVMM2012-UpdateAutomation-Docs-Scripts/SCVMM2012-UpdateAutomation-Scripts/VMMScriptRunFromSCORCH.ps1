param( $VMMServer="vmm2012jp.dcmanager.lab" , 
       $DomainUser = "dcmanagerlab\esdcvsec", 
       $Password = "March2010M2!", 
       $SCCMServer="aaa",
       $SCCMUser="bbb",
       $SCCMPass="ccc",	
       $ScriptFile = "VMMUpdateServerSync.ps1")

$scriptdir="c:\SCVMM\UpdateAutomation"
$scriptout=$scriptdir + "\Output"

$error.Clear();
$domainUser = $Domainuser;
$pass = $PassWord;

$cred = $null;

if ($domainUser)
{
  #Append domain to get domain\username
  #$domainUser = $domain + "\" + $username;

  #Create Cred object
  $securePass = ConvertTo-SecureString -AsPlainText $pass -force
  $cred = New-Object System.Management.Automation.PSCredential $domainUser, $securePass;
}

if ($cred -eq $null)
{
  return 1
}

   $session = New-PSSession -ComputerName $VMMServer -Authentication Default -Credential $cred;
   
   switch($ScriptFile){
	"VMMUpdateServerSync.ps1" {
	   Invoke-Command -Session $session -ArgumentList $VMMServer, $DomainUser, $Password -Filepath $scriptdir\$ScriptFile;
	}
	"VMMUpdateBaselineFromSCCM.ps1" {
	   Invoke-Command -Session $session -ArgumentList $VMMServer, $DomainUser, $Password, $SCCMServer, $SCCMUser, $SCCMPass -Filepath $scriptdir\$ScriptFile ;
	}
	"VMMUpdateComplianceScan.ps1" {
	   Invoke-Command -Session $session -ArgumentList $VMMServer, $DomainUser, $Password -Filepath $scriptdir\$ScriptFile;
	}
	"VMMUpdateComplianceRemediate.ps1" {
	   Invoke-Command -Session $session -ArgumentList $VMMServer, $DomainUser, $Password -Filepath $scriptdir\$ScriptFile ;
	}
	default {
                     return 1
	}
   }

   return 0;