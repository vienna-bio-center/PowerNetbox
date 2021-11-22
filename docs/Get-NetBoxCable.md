---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxCable

## SYNOPSIS
Gets cables form NetBox

## SYNTAX

```
Get-NetBoxCable [-Label <String>] [-Id <Int32>] [-Device <String>] [-Rack <String>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-Cable -Device "ServerA"
Gets all cables for ServerA
```

## PARAMETERS

### -Label
{{ Fill Label Description }}

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

### -Id
ID of the cable

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

### -Device
Name of the parent device

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

### -Rack
Name of the parent rack

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### NetBox.Interface
## NOTES
General notes

## RELATED LINKS
