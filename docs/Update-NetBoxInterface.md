---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Update-NetBoxInterface

## SYNOPSIS
Updates an existing interface in netbox

## SYNTAX

### Byname (Default)
```
Update-NetBoxInterface [-Label <String>] -Type <String> [-MacAddress <String>] [-ManagmentOnly <Boolean>]
 [-Confirm <Boolean>] [<CommonParameters>]
```

### ById
```
Update-NetBoxInterface [-DeviceName <String>] [-DeviceID <Int32>] -Id <Int32> [-Label <String>] -Type <String>
 [-MacAddress <String>] [-ManagmentOnly <Boolean>] [-Confirm <Boolean>] [<CommonParameters>]
```

### ByName
```
Update-NetBoxInterface [-DeviceName <String>] [-DeviceID <Int32>] -Name <String> [-Label <String>]
 -Type <String> [-MacAddress <String>] [-ManagmentOnly <Boolean>] [-Confirm <Boolean>] [<CommonParameters>]
```

### ByDeviceName
```
Update-NetBoxInterface -DeviceName <String> [-Label <String>] -Type <String> [-MacAddress <String>]
 [-ManagmentOnly <Boolean>] [-Confirm <Boolean>] [<CommonParameters>]
```

### ByDeviceId
```
Update-NetBoxInterface -DeviceID <Int32> [-Label <String>] -Type <String> [-MacAddress <String>]
 [-ManagmentOnly <Boolean>] [-Confirm <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Update-NetBoxInterface -Id "1" -Name "NewInterface" -Type "10gbase-t" -MacAddress "00:00:00:00:00:00"
Updates an interface with id "1" to have name "NewInterface" with type "10gbase-t" and MAC address "00:00:00:00:00:00"
```

## PARAMETERS

### -DeviceName
Name of the parent device

```yaml
Type: String
Parameter Sets: ById, ByName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ByDeviceName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceID
ID of the parent device

```yaml
Type: Int32
Parameter Sets: ById, ByName
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: Int32
Parameter Sets: ByDeviceId
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
{{ Fill Name Description }}

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

### -Id
ID of the interface

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

### -Type
Type of the interface

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

### -MacAddress
MAC address of the interface

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

### -ManagmentOnly
Is this interface only for management?

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

### -Confirm
Confirm the chnages to the interface

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
