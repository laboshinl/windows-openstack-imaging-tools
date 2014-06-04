$ErrorActionPreference = "Stop"

function getVirtioDriversFolder(){
    $architectureMapping = @{}
    $architectureMapping['32-bit']='X86'
    $architectureMapping['64-bit']='AMD64'  
    $osVersionMapping = @{}
    $osVersionMapping[0]='VISTA'
    $osVersionMapping[1]='WIN7'
    $osVersionMapping[2]='WIN8'
    $osVersionMapping[3]='WIN8'  

    $osArchitecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
    $archFolder = $architectureMapping[$osArchitecture]
    
    $osVersion = [int]::Parse((Get-WmiObject Win32_OperatingSystem).Version[2])
    $versionFolder = $osVersionMapping[$osVersion]
    if (! $versionFolder) { throw "Unsupported Windows version" }
    
    $virtIOPath = Join-Path -Path $versionFolder -ChildPath $archFolder
    $drive = (gwmi Win32_CDROMDrive | where {(Test-Path (join-path -Path $_.Drive -ChildPath $virtIOPath ))}).Drive
    if (! $drive) { throw "VirtIO drivers not found" }    
    
    return join-path -Path $drive -ChildPath $virtIOPath | join-path -ChildPath "*.inf"
}

$logonScriptPath = "$ENV:SystemRoot\Temp\Logon.ps1"

try
{
    $Host.UI.RawUI.WindowTitle = "Downloading Logon script..."
    $baseUrl = "https://raw.githubusercontent.com/laboshinl/windows-openstack-imaging-tools/master"
    (new-object System.Net.WebClient).DownloadFile("$baseUrl/Logon(x86).ps1", $logonScriptPath)

    $virtPlatform = (gwmi Win32_ComputerSystem).Model
    Write-Host "Virtual platform: $virtPlatform"    
    # TODO: Add XenServer / XCP
    switch($virtPlatform)
    {
        "VMware Virtual Platform"
        {
            # Note: this command will generate a reboot.
            # "/qn REBOOT=ReallySuppress" does not seem to work properly
            $Host.UI.RawUI.WindowTitle = "Installing VMware tools..."
            E:\setup64.exe `/s `/v `/qn `/l `"$ENV:Temp\vmware_tools_install.log`"
            if (!$?) { throw "VMware tools setup failed" }
        }
        {($_ -eq "KVM") -or ($_ -eq "Bochs")}
        {
            $Host.UI.RawUI.WindowTitle = "Downloading VirtIO drivers script..."
            $virtioScriptPath = "$ENV:Temp\InstallVirtIODrivers.js"
            $url = "https://raw.githubusercontent.com/laboshinl/windows-openstack-imaging-tools/master/InstallVirtIODrivers.js"
            (new-object System.Net.WebClient).DownloadFile($url, $virtioScriptPath)
            
            $virtioDriversPath = getVirtioDriversFolder
            Write-Host "Installing VirtIO drivers from: $virtioDriversPath"
            & cscript $virtioScriptPath $virtioDriversPath
            if (!$?) { throw "InstallVirtIO failed" }
            del $virtioScriptPath

            shutdown /r /t 0
        }
    }
}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    # Prevents the setup from proceeding
    if ( Test-Path $logonScriptPath ) { del $logonScriptPath }
    throw
}
