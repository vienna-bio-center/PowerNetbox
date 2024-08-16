function New-DeviceBay {
    <#
    .SYNOPSIS
       Creates a new device bay in NetBox.
    .DESCRIPTION
       This function creates a new device bay in NetBox associated with a specified parent device.
    .EXAMPLE
       PS C:\> New-DeviceBay -DeviceName "Chassis" -Name "Bay1"
       Creates a new device bay named "Bay1" for the device "Chassis".
    .PARAMETER Name
       The name of the device bay to create.
    .PARAMETER DeviceName
       The name of the parent device for the device bay.
    .PARAMETER DeviceID
       The ID of the parent device for the device bay.
    .PARAMETER InstalledDeviceName
       The name of the installed (child) device for the device bay.
    .PARAMETER InstalledDeviceID
       The ID of the installed (child) device for the device bay.
    .PARAMETER Label
       A label for the device bay.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before creating the device bay.
    .PARAMETER Force
       Forces the creation of the device bay even if one already exists with the same name.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.DeviceBay. Returns the created device bay.
    .NOTES
       Ensure that the parent device and any installed devices are present in NetBox before creating a device bay.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $DeviceName,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $DeviceID,

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
            $Device = Get-Device -Name $DeviceName
        }

        if ($DeviceID) {
            $Device = Get-Device -ID $DeviceID
        }

        if ($InstalledDeviceName) {
            $InstalledDevice = Get-Device -Name InstalledDeviceName
        }

        if ($InstalledDeviceID) {
            $InstalledDevice = Get-Device -ID InstalledDeviceID
        }

        $Body = @{
            name             = (Get-Culture).Textinfo.ToTitleCase($Name)
            device           = $Device.ID
            installed_device = $InstalledDevice.ID
        }

        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        $DeviceBay = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
        $DeviceBay.PSObject.TypeNames.Insert(0, "NetBox.DeviceBay")
        return $DeviceBay
    }
}