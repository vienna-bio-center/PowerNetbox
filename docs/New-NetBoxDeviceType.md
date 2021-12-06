---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# New-NetBoxDeviceType

## SYNOPSIS
Cretaes a new device type in NetBox

## SYNTAX

### ByName (Default)
```
New-NetBoxDeviceType -ManufacturerName <String> -Model <String> [-Slug <String>] [-Height <String>]
 [-FullDepth <Boolean>] [-PartNumber <String>] [-Interfaces <Hashtable[]>] [-SubDeviceRole <String>]
 [-InterfaceType <String>] [-PowerSupplyConnector <String>] [-PowerSupplies <Hashtable[]>]
 [-DeviceBays <Hashtable[]>] [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

### ByID
```
New-NetBoxDeviceType -ManufacturerID <Int32> -Model <String> [-Slug <String>] [-Height <String>]
 [-FullDepth <Boolean>] [-PartNumber <String>] [-Interfaces <Hashtable[]>] [-SubDeviceRole <String>]
 [-InterfaceType <String>] [-PowerSupplyConnector <String>] [-PowerSupplies <Hashtable[]>]
 [-DeviceBays <Hashtable[]>] [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
New-NetboxDeviceType -Model "Cisco Catalyst 2960" -Manufacturer "Cisco" -Height "4"
Creates device type "Cisco Catalyst 2960" with height 4 from manufacturer "Cisco" in NetBox
```

## PARAMETERS

### -ManufacturerName
Name of the manufacturer

```yaml
Type: String
Parameter Sets: ByName
Aliases: VendorName

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ManufacturerID
ID of the manufacturer

```yaml
Type: Int32
Parameter Sets: ByID
Aliases: VendorID

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Model
Model of the device type

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Slug
Slug of the device type, if not specified, it will be generated from the model

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Height
Height of the device in U(Units)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullDepth
Is device fulldepth?
defaults to true

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -PartNumber
Partnumber of the device

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interfaces
{{ Fill Interfaces Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubDeviceRole
Subdevice role of the device type, "parent" or "child"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InterfaceType
{{ Fill InterfaceType Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerSupplyConnector
{{ Fill PowerSupplyConnector Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerSupplies
{{ Fill PowerSupplies Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceBays
{{ Fill DeviceBays Description }}

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Confirm the creation of the device type

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force the creation of the device type

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### NetBox.DeviceType
## NOTES
General notes

## RELATED LINKS
