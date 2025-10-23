Project: P02 - HerSafar


Team: 


* Maryam Rizwan – 26100105

* Emaan Waleed – 26100352

* Muhammad – 26100365

* Muhammad Zain Naseer – 26100378

* Kousar Pervaiz – 26100405





PROTOTYPE SUBMISSION GUIDELINES


1. Properly tested working system deployed on an online hosting platform.
2. Code with readable comments uploaded in “Prototype” folder of your project’s Github repository.
3. For prototype phase-2 only: 3-4 minutes video that explains the functionality of the prototype. This must be uploaded in “Prototype” folder of your project’s Github repository.
4. This "Readme" file must be uploaded in the "Prototype" folder. 






------------------------------------------------------------------------------------------------


LIST OF REQUIREMENTS COMPLETED IN THE PROTOTYPE






Sr#
	Use Case Name
	Description
	Developed By
	1
	UC-001 Book a Ride
	System uses Speech Recognition to process input. Searches for and displays suggested ride/carpool match. Commuter confirms their ride.
	Muhammad Zain Naseer – 26100378
	2
	UC-009 Offer Ride (Driver)
	Driver posts availability for offering a ride. Ride is listed and made available for commuters to book.
	Muhammad – 26100365
	3
	Sign Up / Login
	Users can successfully sign up and log in to access their respective interfaces.
	Kousar Pervaiz – 26100405
	

Design (Figma):
   * Login/Sign Up: Emaan Waleed – 26100352

   * Offer Ride & Book a Ride: Maryam Rizwan – 26100105

   * Figma Link

Note: The design prioritizes accessibility and ease of use, especially for female domestic workers. As a group decision, two team members focused on the design while the remaining three worked on development. All team members will code and develop in the next phase.




------------------------------------------------------------------------------------------------


HOW TO ACCESS THE PROTOTYPE


SYSTEM ARCHITECTURE


The prototype consists of two main components:
1. Backend API (Node.js + Express + MongoDB)
2. Frontend App (Flutter Mobile Application)


PREREQUISITES


• Node.js (v18+)
• MongoDB (local or Atlas)
• Flutter SDK
• Android Studio with emulator OR physical Android device


BACKEND API SETUP


Local Development:


1. Clone Repository:


git clone [your-repository-url]
cd FYP-BACKEND


2. Install Dependencies:


npm install


3. Configure Environment:


Create .env file in root directory:


NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/hersafar
JWT_SECRET=YOUR_JWT_SECRET
GEMINI_API_KEY=your_gemini_api_key_here


5. Run Backend Server:
npm run dev
Backend API URL: http://localhost:3000


API Endpoints:


• Health Check: GET http://localhost:3000/
• Sign Up (Request OTP): POST http://localhost:3000/api/auth/signup/request-otp
• Sign Up (Verify): POST http://localhost:3000/api/auth/signup/verify
• Login: POST http://localhost:3000/api/auth/login
• Audio Processing: POST http://localhost:3000/api/audio/process












FRONTEND MOBILE APP SETUP


Local Development:
1. Navigate to Flutter Project:
cd hersafar_app


2. Install Dependencies:
flutter pub get


3. Configure API Connection:


Update lib/constants/app_colors.dart:
For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000/api';


For Real Device (replace with your PC's IP):
static const String baseUrl = 'http://192.168.1.XXX:3000/api';




To find your IP (Windows):
ipconfig
# Look for IPv4 Address




4. Run Flutter App:
# Start Android emulator first, then:
flutter run


------------------------------------------------------------------------------------------------






ADDITIONAL INFORMATION


<Any additional information that you would like the instructors to know>