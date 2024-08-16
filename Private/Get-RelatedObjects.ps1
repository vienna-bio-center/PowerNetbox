function Get-RelatedObjects {
    <#
    .SYNOPSIS
       For internal use, Gets all related objects from a NetBox object.
    .DESCRIPTION
       Retrieves related objects from a NetBox object based on specific properties like "_count".
    .EXAMPLE
       PS C:\> Get-RelatedObjects -Object $Device -ReferenceObjects "devicetype"
       Retrieves related objects for a given device type.
    .PARAMETER Object
       The NetBox object from which to retrieve related objects.
    .PARAMETER ReferenceObjects
       The reference type to determine the related objects.
    .INPUTS
       None
    .OUTPUTS
       List of related NetBox objects.
    .NOTES
       Internal function to help manage relationships in NetBox data.
    #>
    param (
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        $ReferenceObjects
    )

    # Initialize a list to store related objects
    $RelatedObjects = New-Object collections.generic.list[object]

    # Find properties that match the "_count" pattern
    $RelatedTypes = $Object.PSobject.Properties.name -match "_count"
    foreach ($Type in $RelatedTypes) {
        if ($object.$Type -gt 0) {
            # Determine whether to get related objects by Model or Name
            if ($ReferenceObjects -eq "devicetype") {
                $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -Model $($Object.Model)"
            }
            else {
                $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -$($ReferenceObjects) '$($Object.Name)'"
            }
        }
    }

    return $RelatedObjects

    # The following lines appear to be part of another function or commented-out code.
    # Get referenced objects from error message
    $ReferenceObjects = ($ErrorMessage.ErrorRecord | ConvertFrom-Json).Detail.split(":")[1].Split(",")

    # Trim whitespaces from error message
    foreach ($Object in $ReferenceObjects) {
        $Object = $Object.Substring(0, $Object.Length - 3).Substring(1)
    }
    return $ReferenceObjects
}
