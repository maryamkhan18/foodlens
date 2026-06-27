import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import 'product_result_screen.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {

  String barcode = "No Barcode Detected";

  bool isScanned = false;

  Future<void> fetchProduct(String barcode) async {

    final url =
        "https://world.openfoodfacts.org/api/v0/product/$barcode.json";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      if (data["status"] == 1) {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductResultScreen(
              productData: data,
            ),
          ),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product not found"),
          ),
        );

        setState(() {
          isScanned = false;
        });
      }

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("API Error"),
        ),
      );

      setState(() {
        isScanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Barcode Scanner"),
      ),

      body: Column(
        children: [

          Expanded(
            flex: 4,

            child: MobileScanner(

              onDetect: (capture) {

                if (isScanned) return;

                isScanned = true;

                final List<Barcode> barcodes = capture.barcodes;

                for (final code in barcodes) {

                  final scannedCode =
                      code.rawValue ?? "Unknown";

                  setState(() {
                    barcode = scannedCode;
                  });

                  fetchProduct(scannedCode);

                  break;
                }
              },
            ),
          ),

          Expanded(
            flex: 1,

            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Text(
                  barcode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),

                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}