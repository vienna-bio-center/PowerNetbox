function Update-DeviceBay {
    <#
    .SYNOPSIS
       Updates an existing device bay in NetBox.
    .DESCRIPTION
       This function updates an existing device bay in NetBox with new details provided by the user.
    .EXAMPLE
       PS C:\> Update-DeviceBay -DeviceName "Chassis" -Name "Bay1" -InstalledDeviceName "Server1"
       Updates the device bay "Bay1" in "Chassis" to associate it with "Server1".
    .PARAMETER Name
       The name of the device bay to update.
    .PARAMETER DeviceName
       The name of the parent device.
    .PARAMETER DeviceID
       The ID of the parent device.
    .PARAMETER InstalledDeviceName
       The name of the installed (child) device.
    .PARAMETER InstalledDeviceID
       The ID of the installed (child) device.
    .PARAMETER Label
       A label for the device bay.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before updating the device bay.
    .PARAMETER Force
       Forces the update even if it would conflict with existing data.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.DeviceBay. Returns the updated device bay.
    .NOTES
       Ensure that the device and installed device are present in NetBox before updating the device bay.
    #>

    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $DeviceName,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $DeviceID,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Label,

        [Parameter(Mandatory = $false)]
        [String]
        $InstalledDeviceName,

        [Parameter(Mandatory = $false)]
        [String]
        $InstalledDeviceID,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/device-bays/"
    }

    process {
        if ($DeviceName) {
            $Device = Get-Device -Name $DeviceName -Exact
        }

        if ($DeviceID) {
            $Device = Get-Device -ID $DeviceID
        }

        if ($InstalledDeviceName) {
            $InstalledDevice = Get-Device -Name $InstalledDeviceName -Exact
        }

        if ($InstalledDeviceID) {
            $InstalledDevice = Get-Device -ID $InstalledDeviceID
        }

        $DeviceBay = Get-DeviceBay -Name $Name -DeviceId $Device.ID

        $Body = @{
            name             = (Get-Culture).Textinfo.ToTitleCase($Name)
            device           = @{
                id   = $Device.ID
                name = $Device.Name
            }
            installed_device = @{
                name = $InstalledDevice.Name
                id   = $InstalledDevice.ID
            }
        }

        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        $DeviceBay = Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceBay.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
        $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.DeviceBay")
        return $DeviceBay
    }
}
