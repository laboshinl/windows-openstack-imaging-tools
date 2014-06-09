$ErrorActionPreference = "Stop"

try
{
    $Host.UI.RawUI.WindowTitle = "Downloading Cloudbase-Init..."

    $CloudbaseInitMsi = "$ENV:Temp\CloudbaseInitSetup_Beta.msi"
    $CloudbaseInitMsiUrl = "http://xenlet.stu.neva.ru/CloudbaseInitSetup_Beta.msi"
    $CloudbaseInitMsiLog = "$ENV:Temp\CloudbaseInitSetup_Beta.log"

    (new-object System.Net.WebClient).DownloadFile($CloudbaseInitMsiUrl, $CloudbaseInitMsi)

    $Host.UI.RawUI.WindowTitle = "Installing Cloudbase-Init..."

    $p = Start-Process -Wait -PassThru -FilePath msiexec -ArgumentList "/i $CloudbaseInitMsi /qn /l*v $CloudbaseInitMsiLog"
    if ($p.ExitCode -ne 0)
    {
        throw "Installing $CloudbaseInitMsi failed. Log: $CloudbaseInitMsiLog"
    }

     # We're done, remove LogonScript and disable AutoLogon
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name Unattend*
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoLogonCount

    $SetSetupCompleteCmd = "$ENV:ProgramFiles\Cloudbase Solutions\Cloudbase-Init\bin\SetSetupComplete.cmd"
    $unattendedXmlPath = "$ENV:ProgramFiles\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"
    
    If (Test-Path "$ENV:ProgramFiles (x86)") 
    {
        $SetSetupCompleteCmd = "$ENV:ProgramFiles (x86)\Cloudbase Solutions\Cloudbase-Init\bin\SetSetupComplete.cmd"
        $unattendedXmlPath = "$ENV:ProgramFiles (x86)\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"
    }
    
    $Host.UI.RawUI.WindowTitle = "Downloading SetSetupComplete..."
    $SetSetupCompleteUrl = "https://raw.githubusercontent.com/laboshinl/windows-openstack-imaging-tools/master/SetSetupComplete.cmd"
        
    (new-object System.Net.WebClient).DownloadFile($SetSetupCompleteUrl, $SetSetupCompleteCmd)
    

    $Host.UI.RawUI.WindowTitle = "Running SetSetupComplete..."
    & $SetSetupCompleteCmd

    $Host.UI.RawUI.WindowTitle = "Running Sysprep..."
    & "$ENV:SystemRoot\System32\Sysprep\Sysprep.exe" `/generalize `/oobe `/unattend:"$unattendedXmlPath"
}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    throw
}
