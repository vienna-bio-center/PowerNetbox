---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# New-NetBoxPowerPortTemplate

## SYNOPSIS
Creates new port template in netbox

## SYNTAX

### Byname (Default)
```
New-NetBoxPowerPortTemplate -Name <String> [-Label <String>] -Type <String> [-MaxiumDraw <Int32>]
 [-AllocatedDraw <Int32>] [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

### ByName
```
New-NetBoxPowerPortTemplate -DeviceTypeName <String> -Name <String> [-Label <String>] -Type <String>
 [-MaxiumDraw <Int32>] [-AllocatedDraw <Int32>] [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

### ByID
```
New-NetBoxPowerPortTemplate -DeviceTypeID <Int32> -Name <String> [-Label <String>] -Type <String>
 [-MaxiumDraw <Int32>] [-AllocatedDraw <Int32>] [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
New-NetBoxPowerPortTemplate -Name "PSU1"
Creates a new power port template with name "PSU1"
```

## PARAMETERS

### -DeviceTypeName
Name of the Device type of the device

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

### -DeviceTypeID
ID of the Device type of the device

```yaml
Type: Int32
Parameter Sets: ByID
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the power port template

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Label
Label of the power port template

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

### -Type
Type of the power port template

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxiumDraw
Maximum draw of the power port template

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllocatedDraw
{{ Fill AllocatedDraw Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Confirm the creation of the power port template

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
Forces the creation of the power port template

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

### NetBox.PowerPortTemplate
## NOTES
General notes

## RELATED LINKS
