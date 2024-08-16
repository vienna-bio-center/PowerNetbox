function New-PowerPortTemplate {
    <#
    .SYNOPSIS
       Creates a new power port template in NetBox.
    .DESCRIPTION
       This function creates a new power port template in NetBox using the provided parameters.
    .EXAMPLE
       PS C:\> New-PowerPortTemplate -Name "PSU1" -DeviceTypeName "ServerModel" -Type "iec-60320-c14"
       Creates a new power port template named "PSU1" for the device type "ServerModel" with the type "iec-60320-c14".
    .PARAMETER Name
       The name of the power port template.
    .PARAMETER DeviceTypeName
       The name of the device type associated with this power port template.
    .PARAMETER DeviceTypeID
       The ID of the device type associated with this power port template.
    .PARAMETER Type
       The type of the power port (e.g., "iec-60320-c14").
    .PARAMETER Label
       The label for the power port template.
    .PARAMETER MaxiumDraw
       The maximum draw capacity for the power port template.
    .PARAMETER AllocatedPower
       The allocated power for the power port template.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before creating the power port template.
    .PARAMETER Force
       Forces the creation of the power port template even if one with the same name exists.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.PowerPortTemplate
    .NOTES
       Ensure that the device type name or ID provided exists in NetBox.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $DeviceTypeName,

        [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
        [Int32]
        $DeviceTypeID,

        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Label,

        [Parameter(Mandatory = $true)]
        [String]
        $Type,

        [Parameter(Mandatory = $false)]
        [Int32]
        $MaxiumDraw,

        [Parameter(Mandatory = $false)]
        [Int32]
        $AllocatedDraw,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/power-port-templates/"
    }

    process {
        if ($DeviceTypeName) {
            $DeviceType = Get-DeviceType -Model $DeviceTypeName
        }

        if ($DeviceTypeID) {
            $DeviceType = Get-DeviceType -ID $DeviceTypeID
        }

        if (Get-PowerPortTemplate -DeviceTypeID $DeviceType.ID -Name $Name) {
            Write-Warning "PowerPortTemplate $($DeviceType.Model) - $Name already exists"
            $Exists = $true
        }

        $Body = @{
            name           = (Get-Culture).Textinfo.ToTitleCase($Name)
            device_type    = $DeviceType.ID
            type           = $Type
            maximum_draw   = $MaxiumDraw
            allocated_draw = $AllocatedDraw
        }

        # Remove empty keys
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }
        if (-Not $Exists) {
            $PowerPortTemplates = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $PowerPortTemplates.PSObject.TypeNames.Insert(0, "NetBox.PowerPortTemplate")
            return $PowerPortTemplates
        }
        else {
            return
        }
    }
}