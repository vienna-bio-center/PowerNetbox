function Remove-Manufacturer {
    <#
     .SYNOPSIS
        Deletes a manufacturer from NetBox.
     .DESCRIPTION
        Removes a manufacturer from NetBox.
     .EXAMPLE
        PS C:\> Remove-NetBoxManufacturer -Name Dell
        Deletes manufacturer "Dell" from NetBox.
     .PARAMETER Name
        Name of the manufacturer to delete.
     .PARAMETER ID
        ID of the manufacturer to delete.
     .PARAMETER InputObject
        Manufacturer object to delete.
     .INPUTS
        NetBox.Manufacturer
     .OUTPUTS
        None.
     .NOTES
        Deletes a manufacturer from NetBox based on the specified parameters.
     #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $ID,

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
        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/dcim/manufacturers/"
    }

    process {
        # Ensure the input object is of the correct type
        if ($InputObject) {
            $Name = $InputObject.name
            $ID = $InputObject.ID
        }
        if ($Name) {
            $Manufacturer = Get-Manufacturer -Name $Name
        }
        if ($ID) {
            $Manufacturer = Get-Manufacturer -Id $ID
        }

        # Retrieve related objects to delete if the recurse option is enabled
        $RelatedObjects = Get-RelatedObjects -Object $Manufacturer -ReferenceObjects Manufacturer

        # Show confirmation dialog if required
        if ($Confirm) {
            Show-ConfirmDialog -Object $Manufacturer
        }

        # Remove all related objects if recurse is enabled
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        # Delete the manufacturer
        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Manufacturer.ID) + "/") @RestParams -Method Delete
        }
        catch {
            # Handle errors during deletion, especially related object issues
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