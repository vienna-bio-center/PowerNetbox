function Get-PowerSupplyType {
    <#
    .SYNOPSIS
       Retrieves the NetBox-compatible power supply connector type.
    .DESCRIPTION
       This function converts a shorthand power supply connector type into a NetBox-compatible format.
    .EXAMPLE
       PS C:\> Get-PowerSupplyType -PowerSupplyConnector "c14"
       Returns "iec-60320-c14"
    .PARAMETER PowerSupplyConnector
       The shorthand identifier of the power supply connector (e.g., "c14", "c20").
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       String. Returns the NetBox-compatible power supply connector type.
    .NOTES
       Only supports "c14" and "c20" as input values.
    #>
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
