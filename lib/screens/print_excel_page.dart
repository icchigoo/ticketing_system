// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:ticketing_system/provider/serviceProvider.dart';
import 'package:ticketing_system/provider/transactionProvider.dart';

class PrintExcelPage extends StatefulWidget {
  const PrintExcelPage({super.key});

  @override
  _PrintExcelPageState createState() => _PrintExcelPageState();
}

class _PrintExcelPageState extends State<PrintExcelPage> {
  final transactionProvider = TransactionProvider();
  TextEditingController fileNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Excel'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _fetchAndSaveTransactionsAsExcel();
              },
              child: const Text('Fetch and Save as Excel'),
            ),
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                labelText: 'Enter File Name',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTimeDuration(int timeDurationInMinutes) {
    if (timeDurationInMinutes < 60) {
      return '$timeDurationInMinutes minutes';
    } else {
      final hours = timeDurationInMinutes ~/ 60;
      final minutes = timeDurationInMinutes % 60;

      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }

  Future<void> _fetchAndSaveTransactionsAsExcel() async {
    try {
      final transactions = await transactionProvider.fetchTransactions();
      final fileName = fileNameController.text.isEmpty
          ? 'transactions'
          : fileNameController.text;

      // Fetch services to build a map of service IDs to service names
      final serviceProvider = ServiceProvider();
      await serviceProvider.fetchServices(); // Fetch services once

      final services = serviceProvider.services;
      final serviceMap = <int, String>{};

      for (final service in services) {
        final id = service['id'];
        final serviceName = service['serviceName'];
        serviceMap[id] = serviceName;
      }
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Write headers
      sheet.appendRow([
        'Transaction ID',
        'Service Name', 
        'Total Amount',
        'Time Duration',
        'Departure Time',
        'Status',
        'Created At',
        'Updated At',
      ]);

      // Write transaction data
      for (final transaction in transactions) {
        sheet.appendRow([
          transaction['id'],
          serviceMap[transaction['serviceId']], 
          transaction['totalAmount'],
          formatTimeDuration(transaction['timeDuration']),
          transaction['departureTime'],
          transaction['status'],
          transaction['created_at'],
          transaction['updated_at'],
        ]);
      }

      final dir = await getExternalStorageDirectory();
      final excelPath = '${dir?.path}/$fileName.xlsx';

      final file = File(excelPath);
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transactions saved as Excel: $excelPath'),
          ),
        );
      } else {
        throw Exception('Error encoding Excel data.');
      }
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red, 
        ),
      );
    }
  }

  @override
  void dispose() {
    fileNameController.dispose();
    super.dispose();
  }
}
