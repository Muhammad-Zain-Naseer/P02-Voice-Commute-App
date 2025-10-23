import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../book_ride/book_ride_page.dart';
import '../driver/available_rides_page.dart';

class NewHomePage extends StatelessWidget {
  const NewHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏠🏠🏠 NEW_HOME_PAGE LOADED - Driver Mode button IS HERE!');
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC), // Light pink background
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with menu items in Urdu (right to left)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween),
            ),

            // Location row with pin icon and text
            const SizedBox(height: 30),

            // Car icon with HerSafar text
            SvgPicture.asset(
              'assets/icons/car_icon.svg',
              width: 120,
              height: 100,
            ),

            const SizedBox(height: 50),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                ' خوش آمدید، عائشہ!',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCF4374),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Waveform with speaker icon
            SvgPicture.asset(
              'assets/icons/waveform_speaker.svg',
              width: 300,
              height: 90,
            ),

            const SizedBox(height: 30),

            // Instruction text - سواری بُک کرنے کے لیے نیچے دیا گیا بٹن دبائیں۔
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'سواری بُک کرنے کے لیے نیچے دیا گیا بٹن دبائیں۔',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFCF4374),
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Book ride button using the SVG design
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookRidePage()),
                );
              },
              child: Container(
                width: 360,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFCF4374).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/nav_car.svg',
                      width: 36,
                      height: 36,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'رائڈ بُک کریں',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFCE9EF),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Driver Mode Button
            GestureDetector(
              onTap: () {
                print('🚕🚕🚕 DRIVER MODE BUTTON CLICKED!');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AvailableRidesPage(),
                  ),
                );
              },
              child: Container(
                width: 360,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange[800]!, width: 2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_taxi, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'ڈرائیور موڈ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Bottom navigation bar
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavItemSvg('ہوم', 'assets/icons/nav_home.svg'),
                  _buildBottomNavItemSvg(
                    'پروفائل',
                    'assets/icons/nav_profile.svg',
                  ),
                  _buildBottomNavItemSvg(
                    'ایمرجنسی',
                    'assets/icons/nav_emergency.svg',
                  ),
                  _buildBottomNavItem(
                    'گلبرگ، لاہور',
                    Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMenuItem(String text) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildBottomNavItem(String label, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFCF4374), size: 26),
        const SizedBox(height: 4),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBottomNavItemSvg(String label, String svgPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(svgPath, width: 26, height: 26),
        const SizedBox(height: 4),
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
        ),
      ],
    );
  }
}
