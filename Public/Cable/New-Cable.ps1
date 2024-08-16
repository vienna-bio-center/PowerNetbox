function New-Cable {
    <#
    .SYNOPSIS
       Creates a new cable in NetBox.
    .DESCRIPTION
       This function creates a new cable in NetBox between two interfaces on devices.
    .EXAMPLE
       PS C:\> New-Cable -DeviceAName "ServerA" -InterfaceAName "Gig-E 1" -DeviceBName "SwitchB" -InterfaceBName "GigabitEthernet1/0/39" -Type "cat6"
       Creates a new cat6 cable between the specified interfaces on ServerA and SwitchB.
    .PARAMETER DeviceAName
       Name of Endpoint Device A of the cable.
    .PARAMETER InterfaceAName
       Name of Endpoint Interface A of the cable.
    .PARAMETER DeviceAID
       ID of Endpoint Device A of the cable.
    .PARAMETER InterfaceAID
       ID of Endpoint Interface A of the cable.
    .PARAMETER DeviceBName
       Name of Endpoint Device B of the cable.
    .PARAMETER InterfaceBName
       Name of Endpoint Interface B of the cable.
    .PARAMETER DeviceBID
       ID of Endpoint Device B of the cable.
    .PARAMETER InterfaceBID
       ID of Endpoint Interface B of the cable.
    .PARAMETER Label
       The label for the cable.
    .PARAMETER Type
       The type of the cable (e.g., "cat6").
    .PARAMETER Color
       The color of the cable.
    .PARAMETER Length
       The length of the cable.
    .PARAMETER LengthUnit
       The unit of length for the cable.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before creating the cable.
    .PARAMETER Force
       Forces the creation of the cable even if one already exists.
    .INPUTS
       NetBox.Cable
    .OUTPUTS
       NetBox.Cable
    .NOTES
       Ensure that the interfaces and devices specified exist in NetBox.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $false)]
        $DeviceAName,

        [Parameter(Mandatory = $false)]
        [String]
        $InterfaceAName,

        [Parameter(Mandatory = $false)]
        $DeviceAID,

        [Parameter(Mandatory = $false)]
        [String]
        $InterfaceAID,

        [Parameter(Mandatory = $false)]
        $DeviceBName,

        [Parameter(Mandatory = $false)]
        [String]
        $InterfaceBName,

        [Parameter(Mandatory = $false)]
        $DeviceBID,

        [Parameter(Mandatory = $false)]
        [String]
        $InterfaceBID,

        [Parameter(Mandatory = $false)]
        [String]
        $Label,

        [Parameter(Mandatory = $true)]
        [ValidateSet("cat3", "cat5", "cat5e", "cat6", "cat6a", "cat7", "cat7a", "cat8", "dac-active", "dac-passive", "mrj21-trunk", "coaxial", "mmf", "mmf-om1", "mmf-om2", "mmf-om3", "mmf-om4", "mmf-om5", "smf", "smf-os1", "smf-os2", "aoc", "power")]
        [String]
        $Type,

        [Parameter(Mandatory = $false)]
        [String]
        $Color,

        [Parameter(Mandatory = $false)]
        [String]
        $Status,

        [Parameter(Mandatory = $false)]
        [Int32]
        $Length,

        [Parameter(Mandatory = $false)]
        [ValidateSet("km", "m", "cm", "mi", "ft", "in")]
        [String]
        $LengthUnit,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/cables/"
    }

    process {
        # Gather devices and interfaces
        if ($DeviceAName) {
            $DeviceA = Get-Device -Name $DeviceAName -Exact
        }
        else {
            $DeviceA = Get-Device -ID $DeviceAId
        }

        if ($DeviceBName) {
            $DeviceB = Get-Device -Name $DeviceBName -Exact
        }
        else {
            $DeviceB = Get-Device -ID $DeviceBId
        }

        if ($InterfaceAName) {
            $StartPoint = Get-Interface -DeviceID $DeviceA.ID -Name $InterfaceAName
        }
        else {
            $StartPoint = Get-Interface -DeviceID $DeviceA.ID -ID $InterfaceAID
        }

        if ($InterfaceBName) {
            $EndPoint = Get-Interface -DeviceID $DeviceB.ID -Name $InterfaceBName
        }
        else {
            $EndPoint = Get-Interface -DeviceID $DeviceB.ID -ID $InterfaceBID
        }

        if ($null -eq $Startpoint) {
            Write-Error "InterfaceA $InterfaceA does not exist"
            break
        }

        if ($null -eq $Endpoint) {
            Write-Error "InterfaceB $InterfaceB does not exist"
            break
        }

        if ($StartPoint.ID -eq $EndPoint.ID) {
            Write-Error "Cannot create a cable between the same interface"
            break
        }
        if (($Null -ne $StartPoint.Cable) -or ($Null -ne $EndPoint.Cable)) {
            Write-Error "Cannot create a cable between an interface that already has a cable"
            break
        }

        $Body = @{
            termination_a_type = "dcim.interface"
            termination_a_id   = $StartPoint.ID
            termination_b_type = "dcim.interface"
            termination_b_id   = $EndPoint.ID
            type               = $Type
            label              = $Label
            color              = $Color
            status             = $Status
            length             = $Length
            length_unit        = $LengthUnit
        }

        # Remove empty keys
        ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        $Cable = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
        $Cable.PSObject.TypeNames.Insert(0, "NetBox.Cable")
        return $Cable
    }
}