import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PageNotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/error.png',
                fit: BoxFit.cover,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                '404',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: Colors.black38,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Oops! page not found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black38,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
