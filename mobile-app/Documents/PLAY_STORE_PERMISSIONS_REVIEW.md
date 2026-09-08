# Google Play Store Permissions Review

## ⚠️ Permissions Requiring Action in Play Console

### 1. **AD_ID Permission** (CRITICAL)
- **Permission**: `com.google.android.gms.permission.AD_ID`
- **Status**: ⚠️ **REQUIRES DECLARATION**
- **Action Required**: 
  - Go to Google Play Console → Your App → Policy → Data Safety
  - Declare that your app collects Advertising ID
  - Provide justification for why you need this permission
  - If you're using Firebase Analytics/AdMob, this is typically required
- **Risk**: App may be rejected if not properly declared

### 2. **READ_MEDIA_IMAGES Permission**
- **Permission**: `android.permission.READ_MEDIA_IMAGES`
- **Status**: ⚠️ **REQUIRES JUSTIFICATION**
- **Action Required**:
  - In Play Console Data Safety section, explain why your app needs photo access
  - Common reasons: Profile pictures, image uploads, photo editing
  - Be specific about how photos are used
- **Risk**: App may be rejected if justification is unclear

### 3. **RECORD_AUDIO Permission**
- **Permission**: `android.permission.RECORD_AUDIO`
- **Status**: ⚠️ **REQUIRES JUSTIFICATION**
- **Action Required**:
  - In Play Console Data Safety section, explain audio recording usage
  - Common reasons: Voice notes, speech-to-text, voice commands
  - Your app uses speech-to-text, so this is justified
- **Risk**: Medium - Ensure clear explanation in Data Safety form

## ✅ Permissions That Are Safe

### 1. **INTERNET** - ✅ Safe
- Standard permission, no declaration needed

### 2. **POST_NOTIFICATIONS** - ✅ Safe
- Standard for notification functionality
- Already handled at runtime (Android 13+)

### 3. **CAMERA** - ✅ Safe (with justification)
- Common permission for photo capture
- Hardware declared as optional (`required="false"`)

### 4. **Bluetooth Permissions** - ✅ Safe (with proper flags)
- `BLUETOOTH_SCAN` and `NEARBY_WIFI_DEVICES` have `neverForLocation` flag ✅
- Hardware declared as optional ✅
- Old `BLUETOOTH_ADMIN` limited to Android 11 and below ✅

### 5. **USE_BIOMETRIC** - ✅ Safe
- Standard biometric authentication permission

### 6. **RECEIVE_BOOT_COMPLETED** - ✅ Safe
- Needed for scheduled notifications after device reboot

## 📋 Checklist Before Publishing

- [ ] **AD_ID Declaration**: Declared in Play Console Data Safety section
- [ ] **Photo Access Justification**: Explained in Data Safety form
- [ ] **Audio Recording Justification**: Explained in Data Safety form
- [ ] **Privacy Policy**: Updated to mention all data collection
- [ ] **App Description**: Clearly states why permissions are needed
- [ ] **Test on devices without Bluetooth**: Ensure app works (hardware is optional)

## 🔍 Additional Recommendations

1. **Remove AD_ID if not needed**: If you're not using advertising or analytics that require AD_ID, consider removing it to avoid declaration requirements.

2. **Consider Photo Picker API**: For Android 13+, consider using the Photo Picker API instead of `READ_MEDIA_IMAGES` for better privacy and easier Play Store approval.

3. **Review Dependencies**: Some Flutter packages may add permissions automatically. Review your `pubspec.yaml` dependencies.

4. **Data Safety Form**: Fill out the Data Safety form completely in Play Console with accurate information about:
   - What data you collect
   - How you use it
   - Whether you share it with third parties
   - Data security practices

## 📝 Notes

- All Bluetooth permissions have `neverForLocation` flag, which is good for Play Store compliance
- Camera hardware is declared as optional, so app works on devices without cameras
- Bluetooth hardware is declared as optional, so app works on devices without Bluetooth
- Storage permissions are properly scoped (READ_EXTERNAL_STORAGE only for Android ≤12)

