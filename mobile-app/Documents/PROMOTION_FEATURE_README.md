# உன்னத மொய் டிஜிட்டல் சேவை - Promotion & Payment Feature

## 📋 Overview

This feature adds a complete promotion and payment integration to the Moi Kanakku app, allowing users to book digital conversion services for their traditional Moi records.

## ✅ What's Included

### 1. Flutter Pages
- **Promotion Page** (`promotion_page.dart`) - Conversion-focused landing page
- **Booking Success Screen** (`booking_success_screen.dart`) - Post-payment confirmation
- **Contact Us Page** (`contact_us_page.dart`) - Multiple contact options

### 2. Models & Services
- **BookingModel** (`booking_model.dart`) - Data model for bookings
- **BookingServices** (`booking_services.dart`) - API integration service

### 3. Backend API
- **Node.js Example** (`BACKEND_API_EXAMPLE.js`) - Complete backend implementation

## 🚀 Setup Instructions

### Step 1: Install Dependencies

Run the following command in your Flutter project root:

```bash
flutter pub get
```

This will install the `razorpay_flutter: ^1.3.7` package that was added to pubspec.yaml.

### Step 2: Configure Razorpay

1. Sign up at https://razorpay.com
2. Get your API keys from the dashboard
3. Update the Razorpay key in `promotion_page.dart`:

```dart
'key': 'YOUR_RAZORPAY_KEY_ID', // Line 54 in promotion_page.dart
```

### Step 3: Update Contact Information

Update your WhatsApp, phone, and email in:
1. `promotion_page.dart` (line 117)
2. `booking_success_screen.dart` (line 18)
3. `contact_us_page.dart` (lines 50, 59, 68)

```dart
const phoneNumber = '+919876543210'; // Replace with your number
```

### Step 4: Add Routes

Add these routes to your app's routing configuration:

```dart
'/promotion': (context) => const PromotionPage(),
'/booking-success': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
  return BookingSuccessScreen(
    bookingId: args?['bookingId'],
    paymentId: args?['paymentId'],
  );
},
'/contact-us': (context) => const ContactUsPage(),
```

### Step 5: Setup Backend

1. Navigate to your backend project
2. Copy the `BACKEND_API_EXAMPLE.js` content
3. Install dependencies:
```bash
npm install express mysql2 razorpay crypto dotenv cors
```

4. Create `.env` file:
```env
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=moi_db
```

5. Run the server:
```bash
node bookingController.js
```

### Step 6: Configure Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Step 7: Test Payment Flow

1. Run the app: `flutter run`
2. Navigate to Promotion page
3. Click the CTA button
4. Test with Razorpay test cards:
   - Card: 4111 1111 1111 1111
   - CVV: Any 3 digits
   - Expiry: Any future date

## 📱 Features

### Promotion Page
- ✅ Modern premium design with gradient colors
- ✅ Price comparison (₹2,999 vs ₹999)
- ✅ 67% discount badge
- ✅ 30-day countdown timer
- ✅ Feature list with icons
- ✅ Customer testimonial
- ✅ Glowing CTA button
- ✅ Tamil Nadu coverage info

### Payment Integration
- ✅ Razorpay integration
- ✅ UPI, Cards, Netbanking, Wallets support
- ✅ Secure payment handling
- ✅ Payment verification
- ✅ Error handling

### Booking Success Screen
- ✅ Success animation
- ✅ Booking & payment details
- ✅ WhatsApp quick action
- ✅ Call quick action
- ✅ Contact form link
- ✅ Return to home option

### Contact Page
- ✅ WhatsApp integration
- ✅ Phone call integration
- ✅ Email integration
- ✅ Contact form with validation
- ✅ Auto-load user data
- ✅ Tamil Nadu coverage info

## 🗄️ Database Schema

```sql
CREATE TABLE bookings (
  id VARCHAR(36) PRIMARY KEY,
  userId VARCHAR(36) NOT NULL,
  paymentId VARCHAR(255) NOT NULL,
  orderId VARCHAR(255),
  signature VARCHAR(500),
  amount DECIMAL(10, 2) NOT NULL,
  status ENUM('PENDING', 'SUCCESS', 'FAILED') DEFAULT 'PENDING',
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## 🔌 API Endpoints

### 1. Create Booking
```
POST /api/bookings/create

Request:
{
  "userId": "user-id",
  "paymentId": "pay_123",
  "orderId": "order_123",
  "signature": "signature_string",
  "amount": 999,
  "status": "SUCCESS"
}

Response:
{
  "responseType": "S",
  "responseValue": {
    "id": "booking-id",
    "message": "Booking created successfully"
  }
}
```

### 2. Verify Payment
```
POST /api/bookings/verify-payment

Request:
{
  "orderId": "order_123",
  "paymentId": "pay_123",
  "signature": "signature_string"
}

Response:
{
  "responseType": "S",
  "responseValue": {
    "verified": true,
    "message": "Payment verified successfully"
  }
}
```

### 3. List Bookings
```
POST /api/bookings/list

Request:
{
  "userId": "user-id"
}

Response:
{
  "responseType": "S",
  "count": 2,
  "responseValue": [...]
}
```

## 🎨 UI Highlights

### Colors & Styling
- Primary color from theme
- Green accents for success/offer price
- Red accents for urgency/countdown
- Orange/amber for testimonials
- Responsive design with proper spacing

### Tamil Typography
- `appFontFamily` for Tamil text
- `amountFont` for numbers/prices
- Proper font weights and sizes
- Good line height for readability

## 🔒 Security Features

- ✅ Payment signature verification
- ✅ Secure token-based API calls
- ✅ Input validation
- ✅ SQL injection prevention (parameterized queries)
- ✅ Error handling without exposing sensitive info

## 📊 Conversion Optimization

1. **Limited Time Offer** - Creates urgency
2. **Price Comparison** - Shows value (67% discount)
3. **Social Proof** - Customer testimonial
4. **Clear CTA** - Prominent "இப்போது பதிவு செய்யுங்கள்" button
5. **Trust Indicators** - Feature list with icons
6. **Countdown Timer** - 30-day countdown
7. **Coverage Info** - "தமிழ்நாடு முழுவதும்"

## 🧪 Testing Checklist

- [ ] Payment flow works end-to-end
- [ ] Success screen displays correctly
- [ ] WhatsApp/Call integration works
- [ ] Contact form submits properly
- [ ] Backend creates booking entries
- [ ] Payment verification works
- [ ] Error handling for failed payments
- [ ] Responsive on different screen sizes

## 🚨 Important Notes

1. **Replace placeholders**:
   - Razorpay API keys
   - Phone numbers
   - Email addresses
   - Database credentials

2. **Test thoroughly**:
   - Use Razorpay test mode first
   - Test all payment methods
   - Verify database entries
   - Check error scenarios

3. **Production checklist**:
   - Switch to Razorpay live keys
   - Enable proper error logging
   - Add analytics tracking
   - Test on real devices
   - Backup database before launch

## 📞 Support

For issues or questions:
- WhatsApp: [Your Number]
- Email: support@moikanakku.com

## 📄 License

This feature follows the same license as the main Moi Kanakku app.

---

**வாழ்த்துக்கள்!** Your promotion and payment feature is ready! 🎉
