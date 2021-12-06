---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# New-NetBoxInterfaceTemplate

## SYNOPSIS
Creates a new interface template in NetBox

## SYNTAX

### Byname (Default)
```
New-NetBoxInterfaceTemplate -Name <String> [-Label <String>] -Type <String> [-ManagmentOnly <Boolean>]
 [-FindInterfaceType] [-LinkSpeed <String>] [-InterfaceType <String>] [-Confirm <Boolean>] [-Force]
 [<CommonParameters>]
```

### ByName
```
New-NetBoxInterfaceTemplate -Name <String> -DeviceTypeName <String> [-Label <String>] -Type <String>
 [-ManagmentOnly <Boolean>] [-FindInterfaceType] [-LinkSpeed <String>] [-InterfaceType <String>]
 [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

### ById
```
New-NetBoxInterfaceTemplate -Name <String> -DeviceTypeID <Int32> [-Label <String>] -Type <String>
 [-ManagmentOnly <Boolean>] [-FindInterfaceType] [-LinkSpeed <String>] [-InterfaceType <String>]
 [-Confirm <Boolean>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
New-NetBoxInterfaceTemplate -Name "FastEthernet" -Description "FastEthernet" -Type "100base-tx" -DeviceType "Poweredge R6515"
Creates an interface template "FastEthernet" for devicetype "Poweredge R6515" with type "100base-tx"
```

## PARAMETERS

### -Name
Name of the interface template

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

### -DeviceTypeName
Name of the device type

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
ID of the device type

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

### -Label
Label of the interface template

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
Type of the interface template, e.g "1000base-t", "10gbase-x-sfpp" or others

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

### -ManagmentOnly
{{ Fill ManagmentOnly Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FindInterfaceType
{{ Fill FindInterfaceType Description }}

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

### -LinkSpeed
{{ Fill LinkSpeed Description }}

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

### -Confirm
Confirm the creation of the device

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
Force the creation of the device

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

### NetBox.InterfaceTemplate
## NOTES
General notes

## RELATED LINKS
