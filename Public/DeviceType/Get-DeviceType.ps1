function Get-DeviceType {
   <#
     .SYNOPSIS
        Retrieves device types from NetBox.
     .DESCRIPTION
        Retrieves detailed information about device types from the NetBox API based on various filters such as model, manufacturer, ID, and more.
     .EXAMPLE
        PS C:\> Get-NetboxDeviceType -Model "Cisco Catalyst 2960"
        Retrieves DeviceType for "Cisco Catalyst 2960" from NetBox.
     .PARAMETER Model
        The model name of the device type.
     .PARAMETER Manufacturer
        The manufacturer of the device type.
     .PARAMETER ID
        The unique ID of the device type.
     .PARAMETER SubDeviceRole
        Filter device types by their subdevice role.
     .PARAMETER PartNumber
        Filter device types by part number.
     .PARAMETER Slug
        Filter device types by slug.
     .PARAMETER Height
        Filter device types by height.
     .PARAMETER Exact
        Specify if the search should return an exact match instead of a partial one.
     .INPUTS
        None. You cannot pipe objects to this function.
     .OUTPUTS
        Returns a list of device types that match the provided filters.
     .NOTES
        This function interacts with the NetBox API to retrieve device types.
     #>

   [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
   param (
      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("Name")]
      [String]
      $Model,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Alias("Vendor")]
      [String]
      $Manufacturer,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Int32]
      $ID,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $SubDeviceRole,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $PartNumber,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Slug,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [String]
      $Height,

      [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
      [Switch]
      $Exact
   )

   begin {
      # Test configuration and prepare the API endpoint URL
      Test-Config | Out-Null
      $URL = "/dcim/device-types/"
   }

   process {
      # Build the query string based on provided parameters
      $Query = "?"

      if ($Model) {
         $Query += if ($Exact) { "model=$($Model.Replace(" ","%20"))&" } else { "model__ic=$($Model)&" }
      }

      if ($Manufacturer) {
         $Query += "manufacturer_id=$((Get-Manufacturer -Name $Manufacturer).ID)&"
      }

      if ($ID) {
         $Query += "id=$($ID)&"
      }

      if ($SubDeviceRole) {
         $Query += "subdevice_role__ic=$($SubDeviceRole)&"
      }

      if ($PartNumber) {
         $Query += "part_number__ic=$($PartNumber)&"
      }

      if ($Slug) {
         $Query += if ($Exact) { "slug=$($Slug)&" } else { "slug__ic=$($Slug)&" }
      }

      if ($Height) {
         $Query += "u_height=$($Height)&"
      }

      $Query = $Query.TrimEnd("&")

      # Fetch the result from NetBox
      $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

      # Prepare the output as a list of PSCustomObjects
      $DeviceTypes = New-Object collections.generic.list[object]

      foreach ($item in $Result) {
         [PSCustomObject]$DeviceType = $item
         $DeviceType.PSObject.TypeNames.Insert(0, "NetBox.DeviceType")
         $DeviceTypes += $DeviceType
      }

      return $DeviceTypes
   }
}