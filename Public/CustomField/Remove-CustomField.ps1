function Remove-CustomField {
    <#
     .SYNOPSIS
        Deletes a custom field from NetBox.
     .DESCRIPTION
        Removes a custom field from NetBox.
     .EXAMPLE
        PS C:\> Remove-NetBoxCustomField -id 3
        Deletes custom field with ID 3 from NetBox.
     .PARAMETER Name
        Name of the custom field to delete.
     .PARAMETER ID
        ID of the custom field to delete.
     .PARAMETER InputObject
        Custom field object to delete.
     .INPUTS
        NetBox.CustomField
     .OUTPUTS
        None.
     .NOTES
        Deletes a custom field from NetBox based on the specified parameters.
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
        $URL = "/extras/custom-fields/"
    }

    process {
        # Ensure the input object is of the correct type
        if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Customfield")) {
            Write-Error "InputObject is not type NetBox.Customfield"
            break
        }

        # Retrieve the custom field by name or ID
        if ($InputObject) {
            $Name = $InputObject.name
            $ID = $InputObject.Id
        }

        if ($ID) {
            $CustomField = Get-CustomField -Id $ID
        }
        else {
            $CustomField = Get-CustomField -Name $Name
        }

        # Retrieve related objects to delete if the recurse option is enabled
        $RelatedObjects = Get-RelatedObjects -Object $CustomField -ReferenceObjects CustomField

        # Show confirmation dialog if required
        if ($Confirm) {
            Show-ConfirmDialog -Object $CustomField
        }

        # Remove all related objects if recurse is enabled
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        # Delete the custom field
        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($CustomField.ID) + "/") @RestParams -Method Delete
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
