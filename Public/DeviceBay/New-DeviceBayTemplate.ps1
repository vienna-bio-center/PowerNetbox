function New-DeviceBayTemplate {
    <#
    .SYNOPSIS
       Creates a new device bay template in NetBox.
    .DESCRIPTION
       This function creates a new device bay template in NetBox using the provided parameters.
    .EXAMPLE
       PS C:\> New-DeviceBayTemplate -Name "Bay1" -DeviceTypeName "ServerModel"
       Creates a new device bay template named "Bay1" for the device type "ServerModel".
    .PARAMETER Name
       The name of the device bay template.
    .PARAMETER DeviceTypeName
       The name of the device type associated with this device bay template.
    .PARAMETER DeviceTypeID
       The ID of the device type associated with this device bay template.
    .PARAMETER Label
       The label for the device bay template.
    .PARAMETER Description
       A description for the device bay template.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before creating the device bay template.
    .PARAMETER Force
       Forces the creation of the device bay template even if one with the same name exists.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.DeviceBayTemplate. Returns the created device bay template.
    .NOTES
       Ensure that the device type exists in NetBox before attempting to create a template.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false, ParameterSetName = "ByName")]
        [String]
        $DeviceTypeName,

        [Parameter(Mandatory = $false, ParameterSetName = "ByID")]
        [Int32]
        $DeviceTypeID,

        [Parameter(Mandatory = $false)]
        [String]
        $Label,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/device-bay-templates/"
    }

    process {
        if ($DeviceTypeName) {
            $DeviceType = Get-DeviceType -Model $DeviceTypeName
        }

        if ($DeviceTypeID) {
            $DeviceType = Get-DeviceType -ID $DeviceTypeID
        }

        $Body = @{
            name        = (Get-Culture).Textinfo.ToTitleCase($Name)
            device_type = $DeviceType.ID
            label       = $Label
            description = $Description
        }

        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        if (-Not $Exists) {
            $DeviceBayTemplate = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $DeviceBayTemplate.PSObject.TypeNames.Insert(0, "NetBox.DeviceBayTemplate")
            return $DeviceBayTemplate
        }
        else {
            return
        }
    }
}