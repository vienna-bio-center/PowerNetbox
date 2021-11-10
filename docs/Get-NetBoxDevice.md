---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxDevice

## SYNOPSIS
Retrieves a device from NetBox

## SYNTAX

### Byname (Default)
```
Get-NetBoxDevice [<CommonParameters>]
```

### ByName
```
Get-NetBoxDevice -Name <String> [<CommonParameters>]
```

### ByModel
```
Get-NetBoxDevice -Model <String> [<CommonParameters>]
```

### ByManufacturer
```
Get-NetBoxDevice -Manufacturer <String> [<CommonParameters>]
```

### ById
```
Get-NetBoxDevice -Id <Int32> [<CommonParameters>]
```

### ByMac
```
Get-NetBoxDevice -MacAddress <String> [<CommonParameters>]
```

### BySite
```
Get-NetBoxDevice -Site <String> [<CommonParameters>]
```

### ByLocation
```
Get-NetBoxDevice -Location <String> [<CommonParameters>]
```

### ByRack
```
Get-NetBoxDevice -Rack <String> [<CommonParameters>]
```

### ByDeviceType
```
Get-NetBoxDevice -DeviceType <String> [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxdevice -DeviceType "Cisco Catalyst 2960"
Retrieves all devices of type "Cisco Catalyst 2960" from NetBox
```

## PARAMETERS

### -Name
Name of the device

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Model
All devices of this model

```yaml
Type: String
Parameter Sets: ByModel
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Manufacturer
All devices from manufacturer

```yaml
Type: String
Parameter Sets: ByManufacturer
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
ID of the device

```yaml
Type: Int32
Parameter Sets: ById
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MacAddress
MAC address of the device

```yaml
Type: String
Parameter Sets: ByMac
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Site
All devices from Site

```yaml
Type: String
Parameter Sets: BySite
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
All devices from Location

```yaml
Type: String
Parameter Sets: ByLocation
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Rack
All devices from Rack

```yaml
Type: String
Parameter Sets: ByRack
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceType
Device type of the device

```yaml
Type: String
Parameter Sets: ByDeviceType
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
