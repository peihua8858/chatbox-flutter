import 'package:flutter/material.dart';

class MenuData {
  final String imageUrl;
  final String title;

  MenuData({required this.imageUrl, required this.title});
}

class CustomSidebarDrawer extends StatefulWidget {
  final Function drawerClose;

  const CustomSidebarDrawer(
      {super.key,required this.drawerClose});

  @override
  State<StatefulWidget> createState() => _CustiomSidebarState();
}

class _CustiomSidebarState extends State<CustomSidebarDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: 1080 * 0.60,
      height: -1,
      child: Column(
        children: <Widget>[
          Row(children: [
            Image.network("/path/to/image.png")
          ]),
          ListTile(
            onTap: () {
              debugPrint("Tapped Profile");
            },
            leading: Icon(Icons.person),
            title: Text(
              "Your Profile",
            ),
          ),
          Divider(
            height: 1,
            color: Colors.grey,
          ),
          ListTile(
            onTap: () {
              debugPrint("Tapped settings");
            },
            leading: Icon(Icons.settings),
            title: Text("Settings"),
          ),
          Divider(
            height: 1,
            color: Colors.grey,
          ),
          ListTile(
            onTap: () {
              debugPrint("Tapped Log Out");
            },
            leading: Icon(Icons.exit_to_app),
            title: Text("Log Out"),
          ),
        ],
      ),
    );
  }
}
