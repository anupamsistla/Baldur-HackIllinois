import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("About Us", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          centerTitle: true,

        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Say Hi to Baldur!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text(
              "Baldur is designed to help remove large debris in the field that may damage your tools and machinery.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              "Features:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            ListTile(
              leading: Icon(Icons.timer, color: Colors.blue),
              title: Text("Session tracking with real-time stats"),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.blue),
              title: Text("Detailed session history"),
            ),

            SizedBox(height: 20),

            Text(
              "Our Team:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text("Anupam Sai Sistla - Hardware/Backend"),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text("Kaito Sekiya - Hardware/Backend"),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text("Nathan Trinh - Software/Front-end"),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text("Hanel Vujic - Software/Front-end"),
            ),

            Spacer(),
            Center(
              child: Text(
                "Developed with ❤️ by UIC's finest team.",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
