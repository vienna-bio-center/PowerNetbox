---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# New-NetBoxCable

## SYNOPSIS
Creates a new cable in NetBox

## SYNTAX

```
New-NetBoxCable [[-DeviceA] <Object>] [-InterfaceA] <String> [[-DeviceB] <Object>] [-InterfaceB] <String>
 [[-Label] <String>] [-Type] <String> [[-Color] <String>] [[-Status] <String>] [[-Length] <Int32>]
 [[-LengthUnit] <String>] [[-Confirm] <Boolean>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
New-NetBoxCable -InterfaceA "Gig-E 1" -DeviceA ServerA -InterfaceB "GigabitEthernet1/0/39" -DeviceB SwitchB -Label "Super important Cable" -Type cat6 -Color "aa1409" -Length 100 -LengthUnit m
Creates a cable between ServerA, Gig-E 1 and SwitchB, GigabitEthernet1/0/39 with the label "Super important Cable" and the type cat6 and the color "aa1409" and the length 100m
```

## PARAMETERS

### -DeviceA
Endpoint Device A of the cable

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InterfaceA
Endpoint Interface A of the cable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceB
Endpoint Device B of the cable

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InterfaceB
Endpoint Interface B of the cable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Label
Label of the cable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Type of the cable, e.g.
cat6

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Color
Color of the cable, e.g.
"aa1409"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status
{{ Fill Status Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Length
Length of the cable, e.g.
10

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LengthUnit
Length unit of the cable, e.g.
m(eter)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Confirm the creation of the cable

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force the creation of the cable (overwrite existing cable)

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

### NetBox.Cable
## OUTPUTS

### Netbox.Cable
## NOTES
General notes

## RELATED LINKS
