




function Get-ContentType {
   <#
    .SYNOPSIS
       Retrieves content types from NetBox.
    .DESCRIPTION
       Fetches content type information from NetBox based on the provided name filter.
    .EXAMPLE
       PS C:\> Get-NetBoxContentType -Name Device
       Retrieves content type "Device" from NetBox.
    .PARAMETER Name
       Name of the content type to filter by.
    .INPUTS
       None.
    .OUTPUTS
       NetBox.ContentType
    .NOTES
       Retrieves content types from NetBox using the specified filters.
    #>

   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
      [String]
      $Name
   )

   begin {
      # Verify configuration and initialize API endpoint
      Test-Config | Out-Null
      $URL = "/extras/content-types/"
   }

   process {
      # Build query string based on parameters provided
      $Query = ""

      if ($Name) {
         $Query = "?model=$($Name.Replace(' ','').ToLower())"
      }

      $Query = $Query.TrimEnd("&")

      # Make API request and retrieve the results
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Create an empty list to hold the content type objects
      $ContentTypes = New-Object collections.generic.list[object]

      # Process each item in the result and cast to NetBox.ContentType type
      foreach ($Item in $Result) {
         [PSCustomObject]$ContentType = $item
         $ContentType.PSObject.TypeNames.Insert(0, "NetBox.ContentType")
         $ContentTypes += $ContentType
      }

      # Return the list of content types
      return $ContentTypes
   }
}


# function Get-IPRange {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       OptionalParameters
#    )

# }

# function New-IPRange {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       OptionalParameters
#    )
#    FunctionName
# }

# function Remove-IPRange {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       OptionalParameters
#    )

# }

# function Get-IPPrefix {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       OptionalParameters
#    )

# }

# function New-IPPrefix {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       OptionalParameters
#    )
#    FunctionName
# }

# function Remove-IPPrefix {
#    <#
#    .SYNOPSIS
#       Short description
#    .DESCRIPTION
#       Long description
#    .EXAMPLE
#       PS C:\> <example usage>
#       Explanation of what the example does
#    .PARAMETER Name
#       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
#    .INPUTS
#       Inputs (if any)
#    .OUTPUTS
#       Output (if any)
#    .NOTES
#       General notes
#    #>
#    param (
#       OptionalParameters
#    )

# }

# Import all private functions
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse | ForEach-Object {
   . $_.FullName
}

# Import all public functions
Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse | ForEach-Object {
   . $_.FullName
}
