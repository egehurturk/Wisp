# Location Permissions Setup for GPSManager

## Required Info.plist Entries

Add these entries to your app's Info.plist file to enable location services:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Wisp needs location access to track your running route and provide accurate distance and pace measurements during your workout.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Wisp needs location access to track your running route and provide accurate distance and pace measurements during your workout.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Wisp needs location access to track your running route and provide accurate distance and pace measurements during your workout.</string>
```

## Optional Background Location (if needed)

If you need background location updates, add to Info.plist:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## Adding to Xcode Project

### Method 1: Through Xcode UI
1. Open your project in Xcode
2. Select your app target
3. Go to Info tab
4. Click "+" to add new entries
5. Add each key-value pair from above

### Method 2: Direct Info.plist Edit
1. In Xcode, find your app's Info.plist file
2. Right-click and select "Open As" > "Source Code"
3. Add the XML entries above within the `<dict>` tags

## Usage in GPSManager

The GPSManager class automatically handles:
- ✅ Permission requests (`requestLocationPermission()`)
- ✅ Status monitoring (`authorizationStatus`)
- ✅ Error handling for denied permissions
- ✅ Background location support detection

## Privacy Considerations

- The usage descriptions should clearly explain why location access is needed
- Consider requesting "When in Use" first, then "Always" if needed
- The current descriptions focus on workout tracking functionality
- Update descriptions to match your specific use case

## Testing Location Permissions

1. Reset location permissions: iOS Simulator > Device > Location > Custom Location
2. Test different permission states in your app
3. Verify proper error handling for denied permissions
4. Test background location updates if implemented