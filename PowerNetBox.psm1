function Set-Config {
   param (
      [String]
      $NetboxAPIToken,
      [String]
      [ValidatePattern ("^(https:\/\/).+")]
      $NetboxURL
   )
   $Header = @{
      Authorization = "Token $($NetboxAPIToken)"
   }

   $Script:RestParams = @{
      Headers       = $Header
      ContentType   = "application/json"
      ErrorVariable = "RestError"
   }
   $Script:NetboxURL = $NetboxURL.TrimEnd("/")
   Set-Variable -Scope Script -Name NetboxURL

   # Add /api if not already provided
   if ($NetboxURL -notlike "*api*" ) {
      $Script:NetboxURL = $NetboxURL + "/api"
   }
}

function Get-NextPage {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      $Result
   )
   $CompleteResult = New-Object collections.generic.list[object]
   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Get

   $CompleteResult = $Result.Results

   do {
      $Result = Invoke-RestMethod -Uri $Result.next @RestParams -Method Get
      $CompleteResult += $Result.Results
   } until ($null -eq $result.next)

   return $CompleteResult
}

function Get-RelatedObjects {
   <#
   .SYNOPSIS
      Short description
   .DESCRIPTION
      Long description
   .EXAMPLE
      PS C:\> <example usage>
      Explanation of what the example does
   .PARAMETER Name
      The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
   .INPUTS
      Inputs (if any)
   .OUTPUTS
      Output (if any)
   .NOTES
      General notes
   #>
   param (
      $Object,
      $ReferenceObjects
   )

   $RelatedObjects = New-Object collections.generic.list[object]

   $RelatedTypes = $Object.PSobject.Properties.name -match "_count"
   foreach ($Type in $RelatedTypes) {
      if ($object.$Type -gt 0) {
         $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -$($ReferenceObjects) $($Object.Name)"
      }
   }

   return $RelatedObjects

   # Get referenced objects from errormessage
   $ReferenceObjects = ($ErrorMessage.ErrorRecord | ConvertFrom-Json).Detail.split(":")[1].Split(",")



   # Trim whitespaces from errormessage
   foreach ($Object in $ReferenceObjects) {
      $Object = $Object.Substring(0, $Object.Length - 3).Substring(1)
   }

   return $ReferenceObjects

}

function Get-NetBoxInterfaceType {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      $Linkspeed,
      $InterfaceType
   )

   # Determinte 1GE interface
   if ($Linkspeed -eq "1GE" -and $InterfaceType -eq "fixed") {
      $Type = "1000base-t"
   }
   elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "modular") {
      $Type = "1000base-x-sfp"
   }

   # Determinte 10GE interface
   if ($Linkspeed -eq "10GE" -and $InterfaceType -eq "fixed") {
      $Type = "10gbase-t"
   }
   elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "modular") {
      $Type = "10gbase-x-sfpp"
   }

   # Determinte 25GE interface
   if ($Linkspeed -eq "25GE" -and $InterfaceType -eq "fixed") {
      $Type = "25gbase-x-sfp28"
   }
   elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "modular") {
      $Type = "25gbase-x-sfp28"
   }

   return $Type
}

function Get-Site {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name
   )

   $URL = "/dcim/sites/"
   $Query = "?q=$($Name)"

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}

function New-Site {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $false)]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      [String]
      $Status = "active",

      [Parameter(Mandatory = $false)]
      [String]
      $Region,

      [Parameter(Mandatory = $false)]
      [String]
      $Group,

      [Parameter(Mandatory = $false)]
      [String]
      $Tenant,

      [Parameter(Mandatory = $false)]
      [String]
      $CustomFields,

      [Parameter(Mandatory = $false)]
      [String]
      $Comment,

      [Parameter(Mandatory = $false)]
      [String]
      $Tags,

      [Parameter(Mandatory = $false)]
      [String]
      $TagColor,

      [Parameter(Mandatory = $false)]
      [String]
      $Description
   )

   $URL = "/dcim/sites/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   $Body = @{
      name        = $Name
      slug        = $Slug
      status      = $Status
      region      = $Region
      group       = $Group
      tenant      = $Tenant
      comment     = $Comment
      description = $Description
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Update-Site {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $false)]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      [String]
      $Status = "active",

      [Parameter(Mandatory = $false)]
      [String]
      $Region,

      [Parameter(Mandatory = $false)]
      [String]
      $Group,

      [Parameter(Mandatory = $false)]
      [String]
      $Tenant,

      [Parameter(Mandatory = $false)]
      [String]
      $CustomFields,

      [Parameter(Mandatory = $false)]
      [String]
      $Comment,

      [Parameter(Mandatory = $false)]
      [String]
      $Tags,

      [Parameter(Mandatory = $false)]
      [String]
      $TagColor,

      [Parameter(Mandatory = $false)]
      [String]
      $Description
   )
   FunctionName
}

function Remove-Site {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,
      [Switch]
      $Recurse
   )

   $URL = "/dcim/sites/"

   $Site = Get-Site -Name $Name

   $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Site

   if ($Recurse) {
      foreach ($Object in $RelatedObjects) {
         Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
      }
   }

   try {
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Site.id) + "/") @RestParams -Method Delete
   }
   catch {
      if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {

         Write-Warning $(Get-ReferenceItem -ErrorMessage $RestError)
      }
      Write-Warning $(Get-ReferenceItem -ErrorMessage $RestError)
   }
}

function Get-Location {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name
   )

   $URL = "/dcim/locations/"
   $Query = "?q=$($Name)"

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}

function New-Location {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $true)]
      $Site,

      [Parameter(Mandatory = $false)]
      $Parent,

      [Parameter(Mandatory = $false)]
      [String]
      $CustomFields,

      [Parameter(Mandatory = $false)]
      [String]
      $Description
   )

   $URL = "/dcim/locations/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   if ($Site -is [String]) {
      $Site = (Get-Site -Name $Site).ID
   }

   if ($Parent -is [String]) {
      $Parent = (Get-Location -Name $Parent).ID
   }

   $Body = @{
      name        = $Name
      slug        = $Slug
      site        = $Site
      parent      = $Parent
      description = $Description
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Get-Rack {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "BySite")]
      [String]
      $Site
   )

   $URL = "/dcim/racks/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Model) {
      $Query = "?model__ic=$($Model)"
   }

   if ($Manufacturer) {
      $Query = "?manufacturer=$($Manufacturer)"
   }
   if ($Id) {
      $Query = "?id=$($id)"
   }
   if ($MacAddress) {
      $Query = "?mac_address=$($MacAddress)"
   }
   if ($Site) {
      $Query = "?site__ic=$($Site)"
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}


function New-Rack {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $true)]
      $Site,

      [Parameter(Mandatory = $false)]
      $Location,

      [Parameter(Mandatory = $false)]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      [String]
      $Status = "active",

      [Parameter(Mandatory = $false)]
      [ValidateSet("2-post-frame", "4-post-frame", "4-post-cabinet", "wall-frame", "wall-cabinet")]
      [String]
      $Type = "4-post-frame",

      [Parameter(Mandatory = $false)]
      [ValidateSet(10, 19, 21, 23)]
      [Int32]
      $Width = 19,

      [Parameter(Mandatory = $false)]
      [Int32]
      $Height = 42,

      [Parameter(Mandatory = $false)]
      [String]
      $CustomFields,

      [Parameter(Mandatory = $false)]
      [String]
      $Description
   )

   $URL = "/dcim/racks/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   if ($Site -is [String]) {
      $Site = (Get-Site -Name $Site).ID
   }

   if ($Location -is [String]) {
      $Location = (Get-Location -Name $Location).ID
   }

   $Body = @{
      name        = $Name
      slug        = $Slug
      site        = $Site
      location    = $Location
      status      = $Status
      type        = $Type
      width       = $Width
      u_height    = $Height
      description = $Description
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Remove-Rack {

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,
      [Switch]
      $Recurse
   )

   $URL = "/dcim/racks/"

   $Rack = Get-Rack -Name $Name

   $RelatedObjects = Get-RelatedObjects -Object $Rack -ReferenceObjects Rack

   if ($Recurse) {
      Remove-Device

   }


}

function Get-CustomField {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name
   )

   $URL = "/extras/custom-fields/"
   $Query = "?q=$($Name)"

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}

function New-CustomField {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $true)]
      [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
      [String[]]
      $ContentTypes,

      [Parameter(Mandatory = $false)]
      [ValidateSet("text", "integer", "boolean", "date", "url", "select", "multiselect")]
      [String]
      $Type = "4-post-frame",

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
      $Description
   )

   $URL = "/extras/custom-fields/"

   $Body = @{
      name        = $Name
      label       = $Label
      type        = $Type
      required    = $Required
      choices     = $Choices
      description = $Description
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

}

function Get-ContentType {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "SingleItem")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "SingleItem")]
      [Parameter(Mandatory = $false, ParameterSetName = "AllItems")]
      [ValidateSet("Site", "Location", "Rack", "Device", "Device Role")]
      [String]
      $Name,

      [Parameter(Mandatory = $false, ParameterSetName = "SingleItem")]
      [Parameter(Mandatory = $true, ParameterSetName = "AllItems")]
      [Switch]
      $All
   )

   $URL = "/extras/content-types/"
   $Query = "?model=$($Name.Replace(' ',''))"
   if ($All) {
      $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Get
   }
   else {
      $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get
   }

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}
function Get-DeviceType {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "ByModel")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByModel")]
      [String]
      $Model,

      [Parameter(Mandatory = $true, ParameterSetName = "ByManufacturer")]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "Query")]
      [String]
      $Query
   )

   $URL = "/dcim/device-types/"

   if ($Model) {
      $Query = "?model__ic=$($Model)"
   }

   if ($Manufacturer) {
      $Query = "?manufacturer=$($Manufacturer)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($Id) {
      $Query = "?q=$($Query)"
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}

function New-DeviceType {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $true)]
      [String]
      $Model,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $false)]
      [String]
      $Height,

      [Parameter(Mandatory = $false)]
      [Bool]
      $FullDepth = $true,

      [Parameter(Mandatory = $false)]
      [String]
      $PartNumber,

      [Parameter(Mandatory = $false)]
      [Hashtable[]]
      $Interfaces,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("fixed", "modular")]
      $InterfaceType,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("c14", "c20")]
      $PowerSupplyConnector,

      [Parameter(Mandatory = $false)]
      [Hashtable[]]
      $PowerSupplies
   )

   $URL = "/dcim/device-types/"

   $Body = @{
      manufacturer  = $Manufacturer
      model         = $Model
      slug          = $Slug
      part_number   = $PartNumber
      u_height      = $Height
      is_full_depth = $FullDepth
      tags          = $Tags
      custum_fields = $CustomFields
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Get-Device {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ByModel")]
      [String]
      $Model,

      [Parameter(Mandatory = $true, ParameterSetName = "ByManufacturer")]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "ByMac")]
      [String]
      $MacAddress,

      [Parameter(Mandatory = $true, ParameterSetName = "BySite")]
      [String]
      $Site,

      [Parameter(Mandatory = $true, ParameterSetName = "ByRack")]
      [String]
      $Rack
   )
   $URL = "/dcim/devices/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Model) {
      $Query = "?model=$($Model)"
   }

   if ($Manufacturer) {
      $Query = "?manufacturer=$($Manufacturer)"
   }
   if ($Id) {
      $Query = "?id=$($id)"
   }
   if ($MacAddress) {
      $Query = "?mac_address=$($MacAddress)"
   }
   if ($Site) {
      $Query = "?site__ic=$($Site)"
   }

   if ($Rack) {
      $Query = "?rack=$($Rack)"
   }

   $Result = Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get

   if ($Result.Count -gt 50) {
      $Result = Get-NextPage -Result $Result
      return $Result
   }
   else {
      return $Result.Results
   }
}

function New-Device {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (

      [String]
      [Parameter(Mandatory = $true)]
      $Manufacturer,

      [String]
      [Parameter(Mandatory = $true, ParameterSetName = "ByParameter")]
      $Model,

      [String]
      [Parameter(ParameterSetName = "ByParameter")]
      $PartNumber,

      [String]
      [Parameter(ParameterSetName = "ByParameter")]
      $AssetTag,

      [Array]
      [Parameter(Mandatory = $true, ParameterSetName = "ByParameter")]
      $Interfaces,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("fixed", "modular")]
      $InterfaceType,

      [Array]
      [Parameter(Mandatory = $true, ParameterSetName = "ByParameter")]
      $PowerSupplies,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("c14", "c20")]
      $PowerSupplyConnector,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("DataCenter 4.47", "High Density", "Low Density")]
      $Location,

      [String]
      [Parameter(Mandatory = $true)]
      $Rack,

      [String]
      [Parameter(Mandatory = $true)]
      $Position,

      [String]
      [Parameter(Mandatory = $true)]
      $Height,

      [String]
      [Parameter(Mandatory = $true)]
      $Hostname,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("Server", "Switch", "Leafswitch")]
      $DeviceRole,

      [String]
      [ValidateSet("front", "back")]
      $Face = "front",

      [String]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      $Status = "active",

      [Hashtable]
      [Parameter(Mandatory = $false)]
      $CustomFields
   )

   $URL = "/dcim/devices/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }


   $Body = @{
      manufacturer  = $Manufacturer
      model         = $Model
      slug          = $Slug
      part_number   = $PartNumber
      u_height      = $Height
      is_full_depth = $FullDepth
      tags          = $Tags
      custum_fields = $CustomFields
   }

   name          = $Name
   device_type   = Get-DeviceType
   device_role   = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/device-roles/?q=$($DeviceRole)" @RestParams).Results).ID
   site          = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/sites/?q=$($Site)" @RestParams).Results).ID
   location      = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/locations/?q=$($Location)" @RestParams).Results).ID
   rack          = ((Invoke-RestMethod -Uri "$NetBoxAPI/dcim/racks/?q=$($Rack)" @RestParams).Results).ID
   position      = $Position
   face          = $Face
   status        = $Status
   asset_tag     = $AssetTag
   custom_fields = @{
      LOM = $LOM
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Get-InterfaceTemplate {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (

   )

}

function New-InterfaceTemplate {
   <#
    .SYNOPSIS
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       PS C:\> <example usage>
       Explanation of what the example does
    .PARAMETER Name
       The description of a parameter. Add a ".PARAMETER" keyword for each parameter in the function or script syntax.
    .INPUTS
       Inputs (if any)
    .OUTPUTS
       Output (if any)
    .NOTES
       General notes
    #>

   param (
      [Parameter(Mandatory = $true)]
      $DeviceType,

      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      #"virtual", "lag", "100base-tx", "1000base-t", "2.5gbase-t", "5gbase-t", "10gbase-t", "10gbase-cx4", "1000base-x-gbic", "1000base-x-sfp", "10gbase-x-sfpp", "10gbase-x-xfp", "10gbase-x-xenpak", "10gbase-x-x2", "25gbase-x-sfp28", "50gbase-x-sfp56", "40gbase-x-qsfpp", "50gbase-x-sfp28", "100gbase-x-cfp", "100gbase-x-cfp2", "200gbase-x-cfp2", "100gbase-x-cfp4", "100gbase-x-cpak", "100gbase-x-qsfp28", "200gbase-x-qsfp56", "400gbase-x-qsfpdd", "400gbase-x-osfp", "ieee802.11a", "ieee802.11g", "ieee802.11n", "ieee802.11ac", "ieee802.11ad", "ieee802.11ax", "gsm", "cdma", "lte", "sonet-oc3", "sonet-oc12", "sonet-oc48", "sonet-oc192", "sonet-oc768", "sonet-oc1920", "sonet-oc3840", "1gfc-sfp", "2gfc-sfp", "4gfc-sfp", "8gfc-sfpp", "16gfc-sfpp", "32gfc-sfp28", "64gfc-qsfpp", "128gfc-sfp28", "infiniband-sdr", "infiniband-ddr", "infiniband-qdr", "infiniband-fdr10", "infiniband-fdr", "infiniband-edr", "infiniband-hdr", "infiniband-ndr", "infiniband-xdr", "t1", "e1", "t3", "e3", "xdsl", "cisco-stackwise", "cisco-stackwise-plus", "cisco-flexstack", "cisco-flexstack-plus", "juniper-vcp", "extreme-summitstack", "extreme-summitstack-128", "extreme-summitstack-256", "extreme-summitstack-512", "other"
      [Parameter(Mandatory = $true)]
      [String]
      $Type,

      [Parameter(Mandatory = $false)]
      [Bool]
      $ManagmentOnly
   )

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }
   else {
      DeviceType
   }

   $URL = "/dcim/interface-templates/"

   $Body = [PSCustomObject]@{
      device_type = $DeviceType
      name        = $Name
      type        = $(Get-NetBoxInterfaceType -Linkspeed $Interface.Linkspeed -InterfaceType $InterfaceType)
      mgmt_only   = $ManagmentOnly
   }
   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
    ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}
