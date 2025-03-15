import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> _getLocalFile(String name) async {
  final path = await _localPath;
  return File('$path/$name');
}

Future<File> _writeFile(String name, String content) async {
  final file = await _getLocalFile(name);
  return file.writeAsString(content);
}

Future<String> _readFile(String name) async {
  try {
    final file = await _getLocalFile(name);
    return await file.readAsString();
  } catch (e) {
    return "";
  }
}

const _yahooFinanceDataReader = YahooFinanceDailyReader();

Future<YahooFinanceResponse> loadYahooFinanceData(String ticker, {bool fromAsset = false}) async {
  if (kIsWeb && !fromAsset) {
    return _webLoadYahooFinanceData(ticker);
  }
  Map<String, dynamic> json = {};
  String fileName = "$ticker.json";
  if (fromAsset) {
    final content = await rootBundle.loadString('assets/$fileName');
    json = jsonDecode(content);
  } else {
    String cached = await _readFile(fileName);
    if (cached.isNotEmpty) {
      json = jsonDecode(cached);
    } else {
      final now = DateTime.now();
      final period1 = now.subtract(const Duration(days: 365 * 5)).millisecondsSinceEpoch ~/ 1000;
      json = await _yahooFinanceDataReader.getDailyData(ticker, startTimestamp: period1);
      await _writeFile(fileName, jsonEncode(json));
    }
  }
  return YahooFinanceResponse.fromJson(json);
}

Future<YahooFinanceResponse> _webLoadYahooFinanceData(String ticker) async {
  return loadYahooFinanceData(ticker, fromAsset: true);

  // uncomment and run locally
  //    flutter build web --web-browser-flag "--disable-web-security"

  // Map<String, dynamic> json = {};
  // final now = DateTime.now();
  // final period1 = now.subtract(const Duration(days: 365 * 5)).millisecondsSinceEpoch ~/ 1000;
  // final period2 = now.millisecondsSinceEpoch ~/ 1000;
  // final url =
  //     "https://query2.finance.yahoo.com/v8/finance/chart/$ticker?formatted=true&interval=1d&period1=$period1&period2=$period2&symbol=$ticker";
  // final response = await http.get(Uri.parse(url));
  // final content = response.body;
  // json = jsonDecode(content)["chart"]["result"][0];
  // return YahooFinanceResponse.fromJson(json);
}
