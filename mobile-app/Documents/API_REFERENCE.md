# Profile Update API Reference

## Endpoint
```
POST /users/update
```

## Authorization
```
Header: Authorization: Bearer {token}
```

## Request Payload

### Example Request
```json
{
  "id": "123456",
  "name": "Prakash",
  "status": "ACTIVE",
  "gender": "MALE",
  "date_of_birth": "1990-05-15",
  "address_line1": "MRN",
  "address_line2": "Muru",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "country": "India",
  "postal_code": "600001",
  "mobile": "9876543210"
}
```

### Field Descriptions

| Field | Type | Required | Format | Description |
|-------|------|----------|--------|-------------|
| `id` | string | Yes | numeric string | User ID |
| `name` | string | Yes | text | Full name of user |
| `status` | string | Yes | ENUM | Account status: "ACTIVE" or "INACTIVE" |
| `gender` | string | No | ENUM | Gender: "MALE", "FEMALE", "OTHER" or null |
| `date_of_birth` | string | No | YYYY-MM-DD | Birth date in ISO format |
| `address_line1` | string | No | text | Primary address line |
| `address_line2` | string | No | text | Secondary address line |
| `city` | string | No | text | City/Town name |
| `state` | string | No | text | State/Province name |
| `country` | string | No | text | Country name |
| `postal_code` | string | No | alphanumeric | ZIP/Postal code |
| `mobile` | string | No | phone format | Mobile phone number |
| `device_name` | string | No | text | Device name (Android/iOS) |
| `brand` | string | No | text | Device brand (e.g., Xiaomi, Samsung) |
| `model` | string | No | text | Device model (e.g., Redmi Note 10) |
| `manufacturer` | string | No | text | Device manufacturer |
| `androidVersion` | integer | No | numeric | Android API level (e.g., 35 for Android 15) |
| `sdkInt` | integer | No | numeric | SDK version integer |

## Response Format

### Success Response (200 OK)
```json
{
  "responseType": "S",
  "responseValue": {
    "id": "123456",
    "name": "Prakash",
    "email": "prakash@example.com",
    "mobile": "9876543210",
    "status": "ACTIVE",
    "gender": "MALE",
    "date_of_birth": "1990-05-15",
    "address_line1": "MRN",
    "address_line2": "Muru",
    "city": "Chennai",
    "state": "Tamil Nadu",
    "country": "India",
    "postal_code": "600001",
    "profile_image": "path/to/profile/image.jpg",
    "message": "Profile updated successfully"
  }
}
```

### Error Response
```json
{
  "responseType": "E",
  "responseValue": {
    "message": "Validation failed. Please check your input."
  }
}
```

### Network Error Handling
The app handles the following scenarios:
- **No Internet**: Shows "Connection error" toast
- **Server Error (5xx)**: Shows "Server error occurred" toast
- **Invalid Request (4xx)**: Shows API error message
- **Timeout**: Shows "Request timeout" toast

## Implementation Details in App

### Flutter Code
```dart
final params = {
  "id": _user?["id"]?.toString(),
  "name": _nameCtrl.text.trim(),
  "status": _selectedStatus ?? "ACTIVE",
  "gender": _selectedGender,
  "date_of_birth": _selectedDateOfBirth != null
      ? "${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}"
      : null,
  "address_line1": _addressLine1Ctrl.text.trim(),
  "address_line2": _addressLine2Ctrl.text.trim(),
  "city": _cityCtrl.text.trim(),
  "state": _stateCtrl.text.trim(),
  "country": _countryCtrl.text.trim(),
  "postal_code": _postalCodeCtrl.text.trim(),
  "mobile": _mobileCtrl.text.trim(),
};

final response = await _userServices.updateUserDetails(params);
```

## Date Handling

### Format Conversion
- **Input**: User selects date from date picker (DateTime object)
- **Storage**: Converted to `YYYY-MM-DD` format string for API
- **Example**: 
  - User selects: May 15, 1990
  - Sent to API: "1990-05-15"
  - Displayed: "15/05/1990"

### Date Range
- **Minimum**: 1950-01-01
- **Maximum**: Today (current date)

## Validation Rules

### Client-Side Validation
1. **Name**: Cannot be empty
2. **Email**: Cannot be empty (read-only)
3. **Phone**: Optional, but if provided must be valid format
4. **Date of Birth**: Optional, but cannot be future date
5. **Gender**: Optional, dropdown values only
6. **Status**: Defaults to "ACTIVE"
7. **Address Fields**: Optional

### Server-Side Validation
The API is expected to validate:
- All field lengths and formats
- Date format (YYYY-MM-DD)
- Phone number format (country-specific)
- Enum values for gender and status
- Data consistency

## Error Codes

Common server-side error codes:
- `400`: Bad request (invalid data format)
- `401`: Unauthorized (invalid token)
- `403`: Forbidden (permission denied)
- `404`: User not found
- `409`: Conflict (email already exists)
- `422`: Validation failed
- `500`: Internal server error

## Rate Limiting
- Recommended: Implement 1-second debounce for form submission
- API may have rate limiting - implement retry logic with exponential backoff

## Testing Payloads

### Minimal Valid Payload (only required fields)
```json
{
  "id": "123456",
  "name": "John Doe",
  "status": "ACTIVE"
}
```

### Complete Payload (all fields)
```json
{
  "id": "123456",
  "name": "Prakash Kumar",
  "status": "ACTIVE",
  "gender": "MALE",
  "date_of_birth": "1990-05-15",
  "address_line1": "123 Main Street",
  "address_line2": "Apartment 4B",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "country": "India",
  "postal_code": "600001",
  "mobile": "9876543210",
  "device_name": "Android",
  "brand": "Xiaomi",
  "model": "Redmi Note 10",
  "manufacturer": "Xiaomi",
  "androidVersion": 15,
  "sdkInt": 35
}
```

## cURL Examples

### Test Profile Update
```bash
curl -X POST http://192.168.1.4:3000/apis/users/update \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "123456",
    "name": "Prakash",
    "status": "ACTIVE",
    "gender": "MALE",
    "date_of_birth": "1990-05-15",
    "city": "Chennai",
    "mobile": "9876543210"
  }'
```

## Postman Collection

### Request Details
- **Method**: POST
- **URL**: `{{baseUrl}}/users/update`
- **Auth Type**: Bearer Token
- **Token**: `{{authToken}}`
- **Body Type**: JSON raw

### Headers
```
Authorization: Bearer {{authToken}}
Content-Type: application/json
```

## Backend Integration Notes

1. **Validation**: Ensure all optional fields are handled (null checks)
2. **Date Format**: Always expect ISO 8601 format (YYYY-MM-DD)
3. **Enum Values**: Only accept defined values for gender and status
4. **Trimmed Input**: All string inputs are trimmed before sending
5. **Response**: Return updated user data in response for local update
6. **Storage**: Save updated data to local storage after successful API call
7. **UI Update**: Automatically navigate to home screen on success

## Performance Considerations

- Implement debounce/throttle on form submission
- Show loading indicator during API call
- Cache user data locally before update
- Use readonly fields for email (cannot be changed here)
- Consider pagination for large address history (future feature)

## Security Considerations

- All sensitive fields should be encrypted in transit (HTTPS)
- Token should be validated on server
- User ID should be verified against authenticated user
- Implement rate limiting on backend
- Sanitize all input data
- Log all profile updates for audit trail
