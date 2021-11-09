function Set-Config {
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
   Set-Variable -Scope Script -Name NetboxAPIToken

   # Add /api if not already provided
   if ($NetboxURL -notlike "*api*" ) {
      $Script:NetboxURL = $NetboxURL + "/api"
   }
}

function Test-Config {
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

   if (-not $(Get-Variable -Name NetboxURL) -or -not $(Get-Variable -Name NetboxAPIToken) ) {
      Write-Error "NetboxAPIToken and NetboxURL must be set before calling this function"
      break
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
         # Determinte between Models and Names
         if ($ReferenceObjects -eq "devicetype") {
            $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -Model $($Object.Model)"
         }
         else {
            $RelatedObjects += Invoke-Expression "Get-$($Type.TrimEnd("_count")) -$($ReferenceObjects) '$($Object.Name)'"
         }
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

function Show-ConfirmDialog {
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
      $Object
   )

   "Device Model:"
   $Object | Format-List

   $Title = "New Object Creation"
   $Question = "Are you sure you want to create this object?"

   $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
   $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
   $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

   $Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, 1)
   if ($Decision -ne 0) {
      Write-Error "Canceled by User"
      break
   }

}
function Get-InterfaceType {
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
      $Linkspeed,

      [Parameter(Mandatory = $false)]
      [ValidateSet("Fixed", "Modular", "RJ45", "SFP")]
      $InterfaceType
   )


   # "GE" to Linkspeed if missing
   if ($Linkspeed -notlike "*GE") {
      $Linkspeed = $Linkspeed + "GE"
   }

   # Map aliases
   if ($InterfaceType -eq "SFP") {
      $InterfaceType = "Modular"
   }

   if ($InterfaceType -eq "RJ45") {
      $InterfaceType = "Fixed"
   }

   # Determinte 1GE interface
   if ($Linkspeed -eq "1GE" -and $InterfaceType -eq "Fixed") {
      $Type = "1000base-t"
   }
   elseif ($Linkspeed -eq "1GE" -and $InterfaceType -eq "Modular") {
      $Type = "1000base-x-sfp"
   }

   # Determinte 10GE interface
   if ($Linkspeed -eq "10GE" -and $InterfaceType -eq "Fixed") {
      $Type = "10gbase-t"
   }
   elseif ($Linkspeed -eq "10GE" -and $InterfaceType -eq "Modular") {
      $Type = "10gbase-x-sfpp"
   }

   # Determinte 25GE interface
   if ($Linkspeed -eq "25GE") {
      $Type = "25gbase-x-sfp28"
   }

   # Determinte 40GE interface
   if ($Linkspeed -eq "40GE") {
      $Type = "40gbase-x-qsfpp"
   }

   # Determinte 100GE interface
   if ($Linkspeed -eq "100GE") {
      $Type = "100gbase-x-qsfp28"
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

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id
   )

   Test-Config
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
      $Description,

      [Bool]
      $Confirm = $true
   )

   Test-Config
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

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
      $Recurse,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/sites/"

   $Site = Get-Site -Name $Name

   $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Site

   if ($Confirm) {
      Show-ConfirmDialog -Object $Site
   }

   # Remove all related objects
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

         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
      else {
         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }

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

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id
   )

   Test-Config
   $URL = "/dcim/locations/"

   # If name contains spaces, use slug instead
   if ($Name -like " ") {
      $Slug = $Name.tolower() -replace " ", "-"
      $Query = "?slug__ic=$($Slug)"
   }
   else {
      $Query = "?q=$($Name)"
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
      $Description,

      [Bool]
      $Confirm = $true
   )

   Test-Config
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Remove-Location {
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
      $Recurse,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/locations/"

   $Location = Get-Location -Name $Name

   $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Location

   if ($Confirm) {
      Show-ConfirmDialog -Object $Location
   }

   # Remove all related objects
   if ($Recurse) {
      foreach ($Object in $RelatedObjects) {
         Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
      }
   }

   try {
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Location.id) + "/") @RestParams -Method Delete
   }
   catch {
      if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {

         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
      else {
         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }

   }

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

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "BySite")]
      [String]
      $Site,

      [Parameter(Mandatory = $true, ParameterSetName = "ByLocation")]
      [String]
      $Location
   )

   Test-Config
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

   if ($Location) {
      $Query = "?location__ic=$($Location)"
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
      $Description,

      [Bool]
      $Confirm = $true
   )

   Test-Config
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Remove-Rack {

   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Switch]
      $Recurse,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/racks/"

   $Rack = Get-Rack -Name $Name

   $RelatedObjects = Get-RelatedObjects -Object $Rack -ReferenceObjects Rack

   if ($Confirm) {
      Show-ConfirmDialog -Object $Rack
   }

   # Remove all related objects
   if ($Recurse) {
      foreach ($Object in $RelatedObjects) {
         Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
      }
   }
   try {
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Rack.id) + "/") @RestParams -Method Delete
   }
   catch {
      if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {

         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
      else {
         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }

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

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id
   )

   Test-Config
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
      $Description,

      [Bool]
      $Confirm = $true
   )

   Test-Config
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

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

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

   Test-Config
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

function Get-Manufacturer {
   [CmdletBinding(DefaultParameterSetName = "ByName")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "Query")]
      [String]
      $Query
   )

   Test-Config
   $URL = "/dcim/manufacturers/"

   if ($Name) {
      $Query = "?name__ic=$($Name)"
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

function New-Manufacturer {
   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/manufacturers/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   $Body = @{
      name          = $Name
      slug          = $Slug
      custum_fields = $CustomFields
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
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

   Test-Config
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
      [Parameter(Mandatory = $false)]
      [ValidateSet("Fixed", "Modular")]
      $InterfaceType,

      [String]
      [Parameter(Mandatory = $false)]
      [ValidateSet("c14", "c20")]
      $PowerSupplyConnector,

      [Parameter(Mandatory = $false)]
      [Hashtable[]]
      $PowerSupplies,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/device-types/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Model.tolower() -replace " ", "-"
   }

   if ($Manufacturer -is [String]) {
      $Manufacturer = (Get-Manufacturer -Name $Manufacturer).Id
   }
   else {
      $Manufacturer
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

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Remove-DeviceType {
   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Switch]
      $Recurse,

      [Bool]
      $Confirm = $true
   )
   Test-Config
   $URL = "/dcim/device-types/"

   $DeviceType = Get-DeviceType -Model $Name

   $RelatedObjects = Get-RelatedObjects -Object $DeviceType -ReferenceObjects DeviceType

   if ($Confirm) {
      Show-ConfirmDialog -Object $DeviceType
   }

   # Remove all related objects
   if ($Recurse) {
      foreach ($Object in $RelatedObjects) {
         Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
      }
   }

   try {
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceType.id) + "/") @RestParams -Method Delete
   }
   catch {
      if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {

         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
      else {
         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }

   }
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

      [Parameter(Mandatory = $true, ParameterSetName = "ByLocation")]
      [String]
      $Location,

      [Parameter(Mandatory = $true, ParameterSetName = "ByRack")]
      [String]
      $Rack,

      [Parameter(Mandatory = $true, ParameterSetName = "ByDeviceType")]
      [String]
      $DeviceType
   )
   Test-Config
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

   if ($Location) {
      $Query = "?Location__ic=$($Location)"
   }

   if ($Rack) {
      $Query = "?rack=$($Rack)"
   }

   if ($DeviceType) {
      $Query = "?device_type_id=$(Get-DeviceType -Model $($DeviceType) | Select-Object -ExpandProperty id)"
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
      $Name,

      [Parameter(Mandatory = $true)]
      $DeviceType,

      [String]
      [Parameter(Mandatory = $true)]
      [ValidateSet("Server", "Switch", "Leafswitch")]
      $DeviceRole,

      [String]
      [Parameter(Mandatory = $true)]
      $Site,

      [Array]
      [Parameter(Mandatory = $false, ParameterSetName = "ByParameter")]
      $Interfaces,

      [String]
      [Parameter(Mandatory = $false)]
      [ValidateSet("Fixed", "Modular")]
      $InterfaceType,

      [Array]
      [Parameter(Mandatory = $false, ParameterSetName = "ByParameter")]
      $PowerSupplies,

      [String]
      [Parameter(Mandatory = $false)]
      [ValidateSet("c14", "c20")]
      $PowerSupplyConnector,

      [String]
      [Parameter(Mandatory = $false)]
      [ValidateSet("DataCenter 4.47", "High Density", "Low Density")]
      $Location,

      [String]
      [Parameter(Mandatory = $false)]
      $Rack,

      [String]
      [Parameter(Mandatory = $false)]
      $Position,

      [String]
      [Parameter(Mandatory = $false)]
      $Height,

      [String]
      [Parameter(Mandatory = $false)]
      $Hostname,

      [String]
      [Parameter(Mandatory = $false)]
      $ParentDevice,
      [String]
      [ValidateSet("front", "back")]
      $Face = "front",

      [String]
      [Parameter(Mandatory = $false)]
      [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
      $Status = "active",

      [String]
      [Parameter(Mandatory = $false)]
      $AssetTag,

      [Hashtable]
      [Parameter(Mandatory = $false)]
      $CustomFields,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/devices/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }
   else {
      $DeviceType
   }

   $Body = @{
      name        = $Name
      device_type = $DeviceType
      device_role = (Get-DeviceRole -Name $DeviceRole).ID
      site        = (Get-Site -Name $Site).ID
      location    = (Get-Location -Name $Location).ID
      rack        = (Get-Rack -Name $Rack).ID
      position    = $Position
      face        = $Face
      status      = $Status
      asset_tag   = $AssetTag
   }

   if ($ParentDevice) {
      $ParentDevice =
      $Body.parent_device = @{
         name = (Get-Device -Name $ParentDevice).Name
      }
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Remove-Device {
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
      $Recurse,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/devices/"

   $Device = Get-Device -Model $Name

   $RelatedObjects = Get-RelatedObjects -Object $Device -ReferenceObjects Device

   if ($Confirm) {
      Show-ConfirmDialog -Object $Device
   }

   # Remove all related objects
   if ($Recurse) {
      foreach ($Object in $RelatedObjects) {
         Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
      }
   }

   try {
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Device.id) + "/") @RestParams -Method Delete
   }
   catch {
      if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {

         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
      else {
         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
   }

}

function Get-DeviceRole {
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

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id
   )

   Test-Config
   $URL = "/dcim/device-roles/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
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

function New-DeviceRole {
   param (
      [Parameter(Mandatory = $true)]
      [String]
      $Name,

      [Parameter(Mandatory = $false)]
      [String]
      $Slug,

      [Parameter(Mandatory = $false)]
      [String]
      $Color,

      [Parameter(Mandatory = $false)]
      [Bool]
      $VMRole,

      [Parameter(Mandatory = $false)]
      [String]
      $CustomFields,

      [Parameter(Mandatory = $false)]
      [String]
      $Description,

      [Bool]
      $Confirm = $true
   )
   Test-Config
   $URL = "/dcim/device-roles/"

   if ($null -eq $Slug) {
      $Slug
   }
   else {
      $Slug = $Name.tolower() -replace " ", "-"
   }

   $Body = @{
      name        = $Name
      slug        = $Slug
      color       = $Color
      vm_role     = $VMRole
      comment     = $Comment
      description = $Description
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

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

   [CmdletBinding(DefaultParameterSetName = "Byname")]
   param (
      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id
   )

   Test-Config
   $URL = "/dcim/interface-templates/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
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
      $ManagmentOnly,

      [Bool]
      $Confirm = $true
   )

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }
   else {
      $DeviceType
   }

   Test-Config
   $URL = "/dcim/interface-templates/"

   $Body = @{
      device_type = $DeviceType
      name        = $Name
      type        = $(Get-NetBoxInterfaceType -Linkspeed $Interface.Linkspeed -InterfaceType $InterfaceType)
      mgmt_only   = $ManagmentOnly
   }
   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Get-PowerSupplyType {
   param (
      $PowerSupplyConnector
   )

   if ($PowerSupplyConnector -eq "c14") {
      $NetBoxPowerSupplyConnector = "iec-60320-c14"
   }
   if ($PowerSupplyConnector -eq "c20") {
      $NetBoxPowerSupplyConnector = "iec-60320-c20"
   }

   return $NetBoxPowerSupplyConnector
}

function Get-Interface {
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

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [Bool]
      $ManagementOnly
   )

   Test-Config
   $URL = "/dcim/interfaces/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
   }

   if ($ManagementOnly) {
      $Query = "?mgmt_only=$($ManagementOnly.ToString())"
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

function New-Interface {
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
      $Device,

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
      [String]
      $MacAddress,

      [Parameter(Mandatory = $false)]
      [Bool]
      $ManagmentOnly,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/interfaces/"

   if ($Device -is [String]) {
      $Device = (Get-Device -Query $Device).Id
   }
   else {
      $Device
   }

   $Body = @{
      device      = $Device
      name        = $Name
      type        = $Type
      mgmt_only   = $ManagmentOnly
      mac_address = $MacAddress

   }
   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
}

function Update-Interface {
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
      [Parameter(Mandatory = $true)]
      $Device,

      [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
      [String]
      $Name,

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id,

      [Parameter(Mandatory = $false)]
      [String]
      $Label,

      #"virtual", "lag", "100base-tx", "1000base-t", "2.5gbase-t", "5gbase-t", "10gbase-t", "10gbase-cx4", "1000base-x-gbic", "1000base-x-sfp", "10gbase-x-sfpp", "10gbase-x-xfp", "10gbase-x-xenpak", "10gbase-x-x2", "25gbase-x-sfp28", "50gbase-x-sfp56", "40gbase-x-qsfpp", "50gbase-x-sfp28", "100gbase-x-cfp", "100gbase-x-cfp2", "200gbase-x-cfp2", "100gbase-x-cfp4", "100gbase-x-cpak", "100gbase-x-qsfp28", "200gbase-x-qsfp56", "400gbase-x-qsfpdd", "400gbase-x-osfp", "ieee802.11a", "ieee802.11g", "ieee802.11n", "ieee802.11ac", "ieee802.11ad", "ieee802.11ax", "gsm", "cdma", "lte", "sonet-oc3", "sonet-oc12", "sonet-oc48", "sonet-oc192", "sonet-oc768", "sonet-oc1920", "sonet-oc3840", "1gfc-sfp", "2gfc-sfp", "4gfc-sfp", "8gfc-sfpp", "16gfc-sfpp", "32gfc-sfp28", "64gfc-qsfpp", "128gfc-sfp28", "infiniband-sdr", "infiniband-ddr", "infiniband-qdr", "infiniband-fdr10", "infiniband-fdr", "infiniband-edr", "infiniband-hdr", "infiniband-ndr", "infiniband-xdr", "t1", "e1", "t3", "e3", "xdsl", "cisco-stackwise", "cisco-stackwise-plus", "cisco-flexstack", "cisco-flexstack-plus", "juniper-vcp", "extreme-summitstack", "extreme-summitstack-128", "extreme-summitstack-256", "extreme-summitstack-512", "other"
      [Parameter(Mandatory = $true)]
      [String]
      $Type,

      [Parameter(Mandatory = $false)]
      [String]
      $MacAddress,

      [Parameter(Mandatory = $false)]
      [Bool]
      $ManagmentOnly,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/interfaces/"

   if ($Device -is [String]) {
      $Device = (Get-Device -Query $Device).Id
   }
   else {
      $Device
   }

   $Interface = Get-Interface -Name $Name

   $Body = @{
      device      = $Device
      name        = $Name
      type        = $Type
      mgmt_only   = $ManagmentOnly
      mac_address = $MacAddress
   }
   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.id) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
   FunctionName
}

function Remove-Interface {
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
      $Recurse,

      [Bool]
      $Confirm = $true
   )

   Test-Config
   $URL = "/dcim/interfaces/"

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
      Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Interface.id) + "/") @RestParams -Method Delete
   }
   catch {
      if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {

         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
      else {
         Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
      }
   }
}

function Get-PowerPortTemplate {
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

      [Parameter(Mandatory = $true, ParameterSetName = "ById")]
      [Int32]
      $Id
   )

   Test-Config
   $URL = "/dcim/power-port-templates/"

   if ($name) {
      $Query = "?name=$($Name)"
   }

   if ($Id) {
      $Query = "?id=$($id)"
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

function New-PowerPortTemplate {
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

      #"iec-60320-c6", "iec-60320-c8", "iec-60320-c14", "iec-60320-c16", "iec-60320-c20", "iec-60320-c22", "iec-60309-p-n-e-4h", "iec-60309-p-n-e-6h", "iec-60309-p-n-e-9h", "iec-60309-2p-e-4h", "iec-60309-2p-e-6h", "iec-60309-2p-e-9h", "iec-60309-3p-e-4h", "iec-60309-3p-e-6h", "iec-60309-3p-e-9h", "iec-60309-3p-n-e-4h", "iec-60309-3p-n-e-6h", "iec-60309-3p-n-e-9h", "nema-1-15p", "nema-5-15p", "nema-5-20p", "nema-5-30p", "nema-5-50p", "nema-6-15p", "nema-6-20p", "nema-6-30p", "nema-6-50p", "nema-10-30p", "nema-10-50p", "nema-14-20p", "nema-14-30p", "nema-14-50p", "nema-14-60p", "nema-15-15p", "nema-15-20p", "nema-15-30p", "nema-15-50p", "nema-15-60p", "nema-l1-15p", "nema-l5-15p", "nema-l5-20p", "nema-l5-30p", "nema-l5-50p", "nema-l6-15p", "nema-l6-20p", "nema-l6-30p", "nema-l6-50p", "nema-l10-30p", "nema-l14-20p", "nema-l14-30p", "nema-l14-50p", "nema-l14-60p", "nema-l15-20p", "nema-l15-30p", "nema-l15-50p", "nema-l15-60p", "nema-l21-20p", "nema-l21-30p", "cs6361c", "cs6365c", "cs8165c", "cs8265c", "cs8365c", "cs8465c", "ita-c", "ita-e", "ita-f", "ita-ef", "ita-g", "ita-h", "ita-i", "ita-j", "ita-k", "ita-l", "ita-m", "ita-n", "ita-o", "usb-a", "usb-b", "usb-c", "usb-mini-a", "usb-mini-b", "usb-micro-a", "usb-micro-b", "usb-3-b", "usb-3-micro-b", "dc-terminal", "saf-d-grid", "hardwired"
      [Parameter(Mandatory = $true)]
      [String]
      $Type,

      [Parameter(Mandatory = $false)]
      [Int32]
      $MaxiumDraw,

      [Parameter(Mandatory = $false)]
      [Int32]
      $AllocatedDraw,

      [Bool]
      $Confirm = $true
   )

   if ($DeviceType -is [String]) {
      $DeviceType = (Get-DeviceType -Query $DeviceType).Id
   }
   else {
      $DeviceType
   }

   Test-Config
   $URL = "/dcim/power-port-templates/"

   $Body = @{
      device_type    = $DeviceType
      name           = $Name
      type           = $Type
      maximum_draw   = $MaxiumDraw
      allocated_draw = $AllocatedDraw
   }

   # Remove empty keys https://stackoverflow.com/questions/35845813/remove-empty-keys-powershell/54138232
   ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

   if ($Confirm) {
      $OutPutObject = [pscustomobject]$Body
      Show-ConfirmDialog -Object $OutPutObject
   }

   Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)

}

function Remove-PowerPortTemplate {
   param (

   )
   FunctionName
}