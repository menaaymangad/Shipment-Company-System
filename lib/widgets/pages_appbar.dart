import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../pages/main_pages/login_page.dart';

class PagesAppbar extends StatelessWidget {
  const PagesAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Transform.rotate(
            angle: 1 * (3.14159265359 / 180), // Rotate by 1 degree (in radians)
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: SvgPicture.asset(
                'assets/icons/EUKnet Logo.svg',
                width: 50,
                height: 40,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            // width: 50,
            height: 30,
            margin: const EdgeInsets.only(
              left: 10,
              right: 10,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xff236bc9),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Padding(
              padding: EdgeInsets.only(
                left: 5.0,
                right: 5,
              ),
              child: Text(
                'EUKnet',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const Text(
            ' TRANSPORT COMPANY',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          const Text(
            'Logout',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Path 42 (1).svg',
            height: 24,
            width: 24,
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, LoginPage.id);
          },
        ),
      ],
      centerTitle: false,
      titleSpacing: 0,
      elevation: 0,
    );
    
  }
}