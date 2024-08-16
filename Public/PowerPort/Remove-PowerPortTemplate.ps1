function Remove-PowerPortTemplate {
    <#
    .SYNOPSIS
       Removes a power port template from NetBox.
    .DESCRIPTION
       This function deletes a power port template in NetBox using the provided name or input object.
    .EXAMPLE
       PS C:\> Remove-PowerPortTemplate -Name "PSU1"
       Deletes the power port template named "PSU1".
    .PARAMETER Name
       The name of the power port template to remove.
    .PARAMETER Recurse
       If specified, removes all related objects.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before removing the power port template.
    .PARAMETER InputObject
       A pipeline input object representing the power port template to remove.
    .INPUTS
       NetBox.PowerPortTemplate
    .OUTPUTS
       None.
    .NOTES
       Ensure that the power port template exists before attempting to remove it.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Recurse,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
        $InputObject
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/power-port-templates/"
    }

    process {
        if ($InputObject) {
            $Name = $InputObject.Name
        }

        if ($Confirm) {
            Show-ConfirmDialog -Object $InputObject
        }

        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $Name + "/") @RestParams -Method Delete
        }
        catch {
            if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
                Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
                Write-Error "Delete those objects first or run again using -recurse switch"
            }
            else {
                Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            }
        }
    }
}