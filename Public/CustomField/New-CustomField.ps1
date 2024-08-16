function New-CustomField {
    <#
     .SYNOPSIS
        Creates a custom field in NetBox.
     .DESCRIPTION
        Adds a new custom field to NetBox with the specified parameters.
     .EXAMPLE
        PS C:\> New-NetBoxCustomField -Name "ServiceCatalogID" -Type Integer -ContentTypes Device -Label "Service Catalog ID"
        Creates custom field "ServiceCatalogID" of type Integer for content type "Device" with the label "Service Catalog ID" in NetBox.
     .PARAMETER Name
        Name of the new custom field.
     .PARAMETER Label
        Label for the custom field.
     .PARAMETER Type
        Type of the custom field, e.g., "Integer", "Text".
     .PARAMETER ContentTypes
        Content types for the custom field, e.g., "Device".
     .PARAMETER Choices
        Choices for the custom field, e.g., "1,2,3,4,5".
     .PARAMETER Description
        Description of the custom field.
     .PARAMETER Required
        Specifies whether the custom field is required.
     .PARAMETER Confirm
        If set to true, prompts for confirmation before creation.
     .PARAMETER Force
        Forces creation of the custom field, even if it already exists.
     .INPUTS
        None.
     .OUTPUTS
        NetBox.CustomField
     .NOTES
        Adds a new custom field to NetBox using the specified parameters.
     #>

    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
        [String[]]
        $ContentTypes,

        [Parameter(Mandatory = $true)]
        [ValidateSet("text", "integer", "boolean", "date", "url", "select", "multiselect")]
        [String]
        $Type,

        [Parameter(Mandatory = $true)]
        [String]
        $Label,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Required,

        [Parameter(Mandatory = $false)]
        [String[]]
        $Choices,

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
        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/extras/custom-fields/"
    }

    process {
        # Check if the custom field already exists
        if ($(Get-CustomField -Name $Name )) {
            Write-Warning "CustomField $Name already exists"
            $Exists = $true
        }

        # Prepare content types for the API request
        $NetBoxContentTypes = New-Object collections.generic.list[object]

        foreach ($ContentType in $ContentTypes) {
            $NetBoxContentType = Get-ContentType -Name $ContentType
            $NetBoxContentTypes += "$($NetBoxContentType.app_label).$($NetBoxContentType.model)"
        }

        # Prepare the body for the API request
        $Body = @{
            name          = (Get-Culture).Textinfo.ToTitleCase($Name)
            label         = $Label
            type          = $Type
            required      = $Required
            choices       = $Choices
            description   = $Description
            content_types = $NetBoxContentTypes
        }

        # Remove empty keys from the body
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        # Show confirmation dialog if required
        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        # Create the custom field if it doesn't already exist
        if (-Not $Exists) {
            $CustomField = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $CustomField.PSObject.TypeNames.Insert(0, "NetBox.CustomField")
            return $CustomField
        }
        else {
            return
        }
    }
}
