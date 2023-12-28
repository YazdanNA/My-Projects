import 'package:flutter/material.dart';

class MyNavigatorObserver extends NavigatorObserver {
  Future<bool?> willPop(Route<dynamic> route, dynamic result) async {
    bool confirm = await showDialog(
      context: route.navigator!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('آیا می‌خواهید برنامه را ترک کنید؟'),
          actions: [
            TextButton(
              child: Text('خیر'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('بله'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return confirm;
  }
}