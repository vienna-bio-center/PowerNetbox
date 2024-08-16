function Remove-Interface {
    <#
    .SYNOPSIS
       Deletes an interface from NetBox.
    .DESCRIPTION
       This function deletes an interface from NetBox based on the provided name or ID.
    .EXAMPLE
       PS C:\> Remove-NetBoxInterface -ID "1"
       Deletes an interface with ID "1" from NetBox.
    .PARAMETER Name
       The name of the interface to delete.
    .PARAMETER ID
       The ID of the interface to delete.
    .PARAMETER Recurse
       Deletes all related objects associated with the interface.
    .PARAMETER Confirm
       Prompts for confirmation before deleting the interface.
    .PARAMETER InputObject
       The interface object to delete, passed from the pipeline.
    .INPUTS
       NetBox.Interface. You can pipe an interface object to this function.
    .OUTPUTS
       None. This function does not return a value.
    .NOTES
       Ensure that the interface exists in NetBox before attempting to delete it.
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
        $URL = "/dcim/interfaces/"
    }

    process {
        if ($InputObject) {
            $Name = $InputObject.name
        }

        $Interface = Get-Interface -Model $Name

        $RelatedObjects = Get-RelatedObjects -Object $Interface -ReferenceObjects Interface

        if ($Confirm) {
            Show-ConfirmDialog -Object $Interface
        }

        # Remove all related objects
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.ID) + "/") @RestParams -Method Delete
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