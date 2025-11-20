SUBMISSION GUIDELINES [100/100]

1. Properly tested working system deployed on an online hosting platform. [30/30 ]

2. Code with readable comments uploaded in “Prototype” folder of your project’s Github repository.[10/10]

3. 3-4 minutes video that explains the functionality of your system developed so far. This must be uploaded in “Prototype” folder of your project’s Github repository.[10/10]

4. Update project schedule on Github. The schedule must reflect the status of development (completed, in progress, to be done).[10/10]

5. This "Readme" file should be uploaded in Prototype folder.[10/10]

6. Size of the work completed[30/30]


General Comments

Individual grading:


--------------------------------------------------------
PROJECT: P02 - HerSafar

TEAM MEMBERS:
   • Maryam Rizwan – 26100105
   • Emaan Waleed – 26100352
   • Muhammad – 26100365
   • Muhammad Zain Naseer – 26100378
   • Kousar Pervaiz – 26100405


================================================================================================
LIST OF REQUIREMENTS COMPLETED IN THE PROTOTYPE
================================================================================================

1. UC-006: Make Payment
   Developer: Zain Naseer - 26100378
   Description: After the ride is completed and the driver clicks the complete ride button, a pop-up will appear on the driver screen in which he can enter the amount of the ride. In the future, we can select a payment in a way that shows how much kms he had traveled, which is multiplied with some factor to get the fare.

2. UC-004: Trigger SOS
   Developer: Muhammad - 26100365
   Description: The system sends an alert and live GPS location to the trusted contacts. They
   receives the alert and views the location via email

3. UC-007: Rate Ride
   Developer: Maryam Rizwan
   Description: After the ride is completed and payment is processed, the commuter can rate their ride experience. The system allows the commuter to provide a star rating (typically 1-5 stars)  about the driver and the overall ride experience. This rating is recorded in the system and contributes to the driver's overall rating score, helping maintain service quality and accountability.

4. UC-002: Cancel Ride
   Developer: Emaan Waleed - 26100352
   Description: The commuter should be able to cancel the ride if he does not need the 
   ride anymore.

5. UC-005: Share Trip Details
   Developer: Kousar Pervaiz - 26100405
   Description: The commuter should be able to share the trip details to its trusted 
   contacts or friends to let them know about the trip.

================================================================================================
HOW TO ACCESS THE PROTOTYPE
================================================================================================

SYSTEM ARCHITECTURE:
   The prototype consists of two main components:
   1. Backend API (Node.js + Express + MongoDB)
   2. Frontend App (Flutter Mobile Application)

PREREQUISITES:
   • Node.js (v18+)
   • MongoDB (local or Atlas)
   • Flutter SDK
   • Android Studio with emulator OR physical Android device

------------------------------------------------------------------------------------------------
BACKEND API SETUP
------------------------------------------------------------------------------------------------

Local Development:

1. Clone Repository:
   git clone https://github.com/Muhammad-Zain-Naseer/FYP-Backend
   cd FYP-BACKEND

2. Install Dependencies:
   npm install

3. Configure Environment:
   Create .env file in root directory with the following content:
   
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # Logging
   LOG_LEVEL=info
   
   # Gemini API Configuration
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY
   
   # Database
   MONGODB_URI=YOUR_MONGODB_URI
   
   # Authentication
   JWT_SECRET=YOUR_JWT_SECRET
   JWT_EXPIRE=7d
   
   # Email Configuration
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@example.com
   EMAIL_PASSWORD=YOUR_EMAIL_PASSWORD
   EMAIL_FROM=your_email@example.com
   
   # Application
   APP_NAME=HerSafar
   TEST="a"

4. Run Backend Server:
   npm run dev

5. Backend API URL:
   http://localhost:3000

6. Available API Endpoints:

      BASE URL: http://localhost:3000

   -------------------------------------------------------------------------
   AUTHENTICATION ENDPOINTS (/api/auth)
   -------------------------------------------------------------------------
   • Sign Up: 
     POST /api/auth/signup
   
   • Verify Email: 
     GET /api/auth/verify-email
   
   • Resend Verification Email: 
     POST /api/auth/resend-verification-email
   
   • Login: 
     POST /api/auth/login

   -------------------------------------------------------------------------
   RIDE ENDPOINTS (/api/rides)
   -------------------------------------------------------------------------
   • Get Ride Statistics: 
     GET /api/rides/stats
   
   • Get Pending Rides: 
     GET /api/rides/pending
   
   • Create New Ride Request: 
     POST /api/rides/
     Body: {source, destination, userId?, userName?, sourceCoordinates?, destinationCoordinates?}
   
   • Get All Rides (with filters): 
     GET /api/rides/
     Query: status?, userId?
   
   • Get Specific Ride by ID: 
     GET /api/rides/:id
   
   • Match Ride with Driver: 
     POST /api/rides/:id/match
     Body: {driverId, driverName?}
   
   • Cancel Ride: 
     DELETE /api/rides/:id
   
   • Rate Completed Ride: 
     POST /api/rides/:id/rate
     Body: {rating}
   
   • Trigger SOS Alert: 
     POST /api/rides/:id/sos
     Body: {location?, message?}
   
     -------------------------------------------------------------------------
   PAYMENT ENDPOINTS (/api/payments)
   -------------------------------------------------------------------------
   • Get Payment Statistics: 
     GET /api/payments/stats
     Query: userId?, driverId?
   
   • Get Payment by Ride ID: 
     GET /api/payments/ride/:rideId
   
   • Get Payments by User ID: 
     GET /api/payments/user/:userId
     Query: status?
   
   • Get Payments by Driver ID: 
     GET /api/payments/driver/:driverId
     Query: status?
   
   • Submit Payment: 
     POST /api/payments/
     Body: {rideId, userId, driverId, amount, transactionId, paymentScreenshot, 
            paymentMethod?, notes?}
   
   • Get Payment by ID: 
     GET /api/payments/:id
   
   • Update Payment Status: 
     PATCH /api/payments/:id/status
     Body: {status, notes?, verifiedBy?}

   -------------------------------------------------------------------------
   SHARE RIDE DETAILS ENDPOINTS (/api/trusted-contacts)
   -------------------------------------------------------------------------
   • Get Trusted Contacts: 
     GET /api/trusted-contacts/:userId

 • Share Ride Details with Selected Contacts: 
     POST /api/rides/share-ride-details-selected

   -------------------------------------------------------------------------
   AUDIO PROCESSING ENDPOINTS (/api/audio)
   -------------------------------------------------------------------------
   • Process Audio (Extract Locations): 
     POST /api/audio/process
     Body: multipart/form-data with 'audio' field
   
   • Audio Service Health Check: 
     GET /api/audio/health



------------------------------------------------------------------------------------------------
FRONTEND MOBILE APP SETUP
------------------------------------------------------------------------------------------------

Local Development:

1. Navigate to Flutter Project:
   cd hersafar_app

2. Install Dependencies:
   flutter pub get

3. Configure API Connection:
   Update lib/constants/app_colors.dart:
   
   For Android Emulator:
   static const String baseUrl = 'http://10.0.2.2:3000/api';
   
   For Real Device (replace XXX with your PC's IP address):
   static const String baseUrl = 'http://192.168.1.XXX:3000/api';
   
   To find your IP address (Windows):
   ipconfig
   # Look for IPv4 Address

4. Run Flutter App:
   # Start Android emulator first, then run:
   flutter run

------------------------------------------------------------------------------------------------
TEST CREDENTIALS (if applicable):
------------------------------------------------------------------------------------------------
   [Add test user credentials here if available]
   
   Example:
   • Test Commuter:
     Email: kousarpervaiz13@gmail.com
     PIN: 1234
   
   • Test Driver:
     Email: kousarpervaiz18@gmail.com
    PIN: 1234
   ================================================================================================
ADDITIONAL INFORMATION
================================================================================================

Technology Stack:
   • Backend: Node.js, Express.js, MongoDB Atlas
   • Frontend: Flutter (Mobile Application)
   • APIs: Gemini API for AI features
   • Authentication: JWT (JSON Web Tokens)
   • Email Service: Gmail SMTP

Key Features Implemented:
   • Payment processing (digital and cash options)
   • Emergency SOS system with live GPS tracking
   • Ride cancellation functionality
   • Trip details sharing with trusted contacts

Important Notes:
   • The backend uses MongoDB Atlas cloud database - no local MongoDB setup required
   • Email notifications are configured through Gmail SMTP
   • Audio processing capabilities are integrated for emergency features
   • Ensure proper network connectivity for API communication between mobile app and    backend

Testing Instructions:
   1. Start the backend server first (npm run dev)
   2. Verify backend is running by accessing http://localhost:3000/
   3. Configure the Flutter app with correct API endpoint
   4. Run the mobile app on emulator or physical device
   5. Test each use case functionality through the mobile interface

Repository:
   • Backend: https://github.com/Muhammad-Zain-Naseer/FYP-Backend
   • Frontend: [https://github.com/Muhammad-Zain-Naseer/FYP-Frontend-Flutter]

================================================================================================


