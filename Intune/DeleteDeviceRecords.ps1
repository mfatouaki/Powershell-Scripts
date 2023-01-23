[CmdletBinding(DefaultParameterSetName='All')]
Param
(
    [Parameter(ParameterSetName='All',Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Individual',Mandatory=$true,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    $ComputerName,
    [Parameter(ParameterSetName='All')]
    [switch]$All = $True,
    [Parameter(ParameterSetName='Individual')]
    [switch]$AD,
    [Parameter(ParameterSetName='Individual')]
    [switch]$AAD,
    [Parameter(ParameterSetName='Individual')]
    [switch]$Intune,
    [Parameter(ParameterSetName='Individual')]
    [switch]$Autopilot,
    [Parameter(ParameterSetName='Individual')]
    [switch]$ConfigMgr
)

Set-Location $env:SystemDrive

# Load required modules
If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("ConfigMgr") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Importing modules..." -NoNewline
        If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
        {
            Import-Module Microsoft.Graph.Intune -ErrorAction Stop
        }
        If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("All"))
        {
            Import-Module AzureAD -ErrorAction Stop
        }
        If ($PSBoundParameters.ContainsKey("ConfigMgr") -or $PSBoundParameters.ContainsKey("All"))
        {
            Import-Module $env:SMS_ADMIN_UI_PATH.Replace('i386','ConfigurationManager.psd1') -ErrorAction Stop
        }
        Write-host "Success" -ForegroundColor Green 
    }
    Catch
    {
        Write-host "$($_.Exception.Message)" -ForegroundColor Red
        Return
    }
}

# Authenticate with Azure
If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-Host "Authenticating with MS Graph and Azure AD..." -NoNewline
        $intuneId = Connect-MSGraph -ErrorAction Stop
        $aadId = Connect-AzureAD -AccountId $intuneId.UPN -ErrorAction Stop
        Write-host "Success" -ForegroundColor Green
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        Write-host "$($_.Exception.Message)" -ForegroundColor Red
        Return
    }
}

Write-host "$($ComputerName.ToUpper())" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow

# Delete from AD
If ($PSBoundParameters.ContainsKey("AD") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Retrieving " -NoNewline
        Write-host "Active Directory " -ForegroundColor Yellow -NoNewline
        Write-host "computer account..." -NoNewline   
        $Searcher = [ADSISearcher]::new()
        $Searcher.Filter = "(sAMAccountName=$ComputerName`$)"
        [void]$Searcher.PropertiesToLoad.Add("distinguishedName")
        $ComputerAccount = $Searcher.FindOne()
        If ($ComputerAccount)
        {
            Write-host "Success" -ForegroundColor Green
            Write-Host "   Deleting computer account..." -NoNewline
            $DirectoryEntry = $ComputerAccount.GetDirectoryEntry()
            $Result = $DirectoryEntry.DeleteTree()
            Write-Host "Success" -ForegroundColor Green
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        $_
    }
}

# Delete from Azure AD
If ($PSBoundParameters.ContainsKey("AAD") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Retrieving " -NoNewline
        Write-host "Azure AD " -ForegroundColor Yellow -NoNewline
        Write-host "device record/s..." -NoNewline 
        [array]$AzureADDevices = Get-AzureADDevice -SearchString $ComputerName -All:$true -ErrorAction Stop
        If ($AzureADDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            Foreach ($AzureADDevice in $AzureADDevices)
            {
                Write-host "   Deleting DisplayName: $($AzureADDevice.DisplayName)  |  ObjectId: $($AzureADDevice.ObjectId)  |  DeviceId: $($AzureADDevice.DeviceId) ..." -NoNewline
                Remove-AzureADDevice -ObjectId $AzureADDevice.ObjectId -ErrorAction Stop
                Write-host "Success" -ForegroundColor Green
            }      
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        $_
    }
}

# Delete from Intune
If ($PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Retrieving " -NoNewline
        Write-host "Intune " -ForegroundColor Yellow -NoNewline
        Write-host "managed device record/s..." -NoNewline
        [array]$IntuneDevices = Get-IntuneManagedDevice -Filter "deviceName eq '$ComputerName'" -ErrorAction Stop
        If ($IntuneDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            If ($PSBoundParameters.ContainsKey("Intune") -or $PSBoundParameters.ContainsKey("All"))
            {
                foreach ($IntuneDevice in $IntuneDevices)
                {
                    Write-host "   Deleting DeviceName: $($IntuneDevice.deviceName)  |  Id: $($IntuneDevice.Id)  |  AzureADDeviceId: $($IntuneDevice.azureADDeviceId)  |  SerialNumber: $($IntuneDevice.serialNumber) ..." -NoNewline
                    Remove-IntuneManagedDevice -managedDeviceId $IntuneDevice.Id -Verbose -ErrorAction Stop
                    Write-host "Success" -ForegroundColor Green
                }
            }
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        $_
    }
}

# Delete Autopilot device
If ($PSBoundParameters.ContainsKey("Autopilot") -or $PSBoundParameters.ContainsKey("All"))
{
    If ($IntuneDevices.Count -ge 1)
    {
        Try
        {
            Write-host "Retrieving " -NoNewline
            Write-host "Autopilot " -ForegroundColor Yellow -NoNewline
            Write-host "device registration..." -NoNewline
            $AutopilotDevices = New-Object System.Collections.ArrayList
            foreach ($IntuneDevice in $IntuneDevices)
            {
                $URI = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($IntuneDevice.serialNumber)')"
                $AutopilotDevice = Invoke-MSGraphRequest -Url $uri -HttpMethod GET -ErrorAction Stop
                [void]$AutopilotDevices.Add($AutopilotDevice)
            }
            Write-Host "Success" -ForegroundColor Green

            foreach ($device in $AutopilotDevices)
            {
                Write-host "   Deleting SerialNumber: $($Device.value.serialNumber)  |  Model: $($Device.value.model)  |  Id: $($Device.value.id)  |  GroupTag: $($Device.value.groupTag)  |  ManagedDeviceId: $($device.value.managedDeviceId) ..." -NoNewline
                $URI = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$($device.value.Id)"
                $AutopilotDevice = Invoke-MSGraphRequest -Url $uri -HttpMethod DELETE -ErrorAction Stop
                Write-Host "Success" -ForegroundColor Green
            }
        }
        Catch
        {
            Write-host "Error!" -ForegroundColor Red
            $_
        }
    }
}

# Delete from ConfigMgr
If ($PSBoundParameters.ContainsKey("ConfigMgr") -or $PSBoundParameters.ContainsKey("All"))
{
    Try
    {
        Write-host "Retrieving " -NoNewline
        Write-host "ConfigMgr " -ForegroundColor Yellow -NoNewline
        Write-host "device record/s..." -NoNewline
        $SiteCode = (Get-PSDrive -PSProvider CMSITE -ErrorAction Stop).Name
        Set-Location ("$SiteCode" + ":") -ErrorAction Stop
        [array]$ConfigMgrDevices = Get-CMDevice -Name $ComputerName -Fast -ErrorAction Stop
        Write-Host "Success" -ForegroundColor Green
        foreach ($ConfigMgrDevice in $ConfigMgrDevices)
        {
            Write-host "   Deleting Name: $($ConfigMgrDevice.Name)  |  ResourceID: $($ConfigMgrDevice.ResourceID)  |  SMSID: $($ConfigMgrDevice.SMSID)  |  UserDomainName: $($ConfigMgrDevice.UserDomainName) ..." -NoNewline
            Remove-CMDevice -InputObject $ConfigMgrDevice -Force -ErrorAction Stop
            Write-Host "Success" -ForegroundColor Green
        }
    }
    Catch
    {
        Write-host "Error!" -ForegroundColor Red
        $_
    }
}

Set-Location $env:SystemDrive
