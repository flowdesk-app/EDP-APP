import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import '../models/supplier_model.dart';
import '../models/user_model.dart';
import '../models/bin_box_balance_model.dart';
import '../models/bin_box_return_model.dart';
import '../models/notification_model.dart';
import '../models/lead_model.dart';
import 'package:flutter/foundation.dart';
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Using the host machine's LAN IP address or localhost
  String get baseUrl {
    // If you run on Android Emulator, change this to http://10.0.2.2:5001/api
    return 'https://edp-app-unq5.onrender.com/api';
  }
  String? _token;
  UserModel? currentUser;

  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    final roleStr = prefs.getString('auth_role');
    if (roleStr != null) {
      currentUser = UserModel(
        email: prefs.getString('auth_email') ?? '',
        password: '',
        role: roleStr == 'admin' ? UserRole.admin : UserRole.employee,
      );
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<UserModel?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        final roleStr = data['role'] == 'admin' ? 'admin' : 'employee';
        await prefs.setString('auth_role', roleStr);
        await prefs.setString('auth_email', data['email']);
        
        currentUser = UserModel(
          email: data['email'],
          password: '',
          role: roleStr == 'admin' ? UserRole.admin : UserRole.employee,
          supplierId: data['supplierId'],
        );
        return currentUser;
      }
    } catch (e) {
      // Ignored in production
    }
    return null;
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('auth_email');
  }

  Future<List<JobModel>> getJobsForOwner() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/jobs'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => _mapJob(d)).toList();
    }
    return [];
  }

  Future<List<JobModel>> getJobsForSupplier() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/jobs/supplier'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => _mapJob(d)).toList();
    }
    return [];
  }

  Future<List<SupplierModel>> getSuppliers() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/suppliers'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => SupplierModel(supplierId: d['_id'], supplierName: d['supplierName'])).toList();
    }
    return [];
  }

  Future<List<String>> getCustomers() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/customers'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => d['customerName'] as String).toList();
    }
    return [];
  }

  Future<List<String>> getParts() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/parts'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => d['partNumber'] as String).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPartObjects() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/parts'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => d as Map<String, dynamic>).toList();
    }
    return [];
  }

  Future<void> deletePart(String id) async {
    await _loadToken();
    await http.delete(Uri.parse('$baseUrl/parts/$id'), headers: _headers);
  }

  Future<void> createPart(String partNumber, String description) async {
    await _loadToken();
    await http.post(
      Uri.parse('$baseUrl/parts'),
      headers: _headers,
      body: jsonEncode({'partNumber': partNumber, 'partDescription': description, 'customer': 'Default'}),
    );
  }

  Future<void> addSupplier(String name) async {
    await _loadToken();
    await http.post(
      Uri.parse('$baseUrl/suppliers'),
      headers: _headers,
      body: jsonEncode({'supplierName': name}),
    );
  }

  Future<void> addCustomer(String name) async {
    await _loadToken();
    await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: _headers,
      body: jsonEncode({'customerName': name}),
    );
  }

  Future<void> createSupplier(String name) async {
    await _loadToken();
    await http.post(
      Uri.parse('$baseUrl/suppliers'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
  }

  Future<List<String>> getLogistics() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/logistics'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => d['name'] as String).toList();
    }
    return [];
  }

  Future<void> createLogistics(String name) async {
    await _loadToken();
    await http.post(
      Uri.parse('$baseUrl/logistics'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
  }

  Future<void> deleteSupplier(String supplierId) async {
    await _loadToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/suppliers/$supplierId'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to delete supplier');
  }

  Future<void> updateSupplier(String supplierId, String newName) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/suppliers/$supplierId'),
      headers: _headers,
      body: jsonEncode({'supplierName': newName}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update supplier');
  }

  Future<List<dynamic>> getWarehouseItems() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/warehouse'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  Future<List<NotificationModel>> getNotifications() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => NotificationModel.fromJson(d)).toList();
    }
    return [];
  }

  Future<void> deleteNotifications(List<String> ids) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/notifications/delete-bulk'),
      headers: _headers,
      body: jsonEncode({'ids': ids}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to delete notifications: ${res.body}');
    }
  }

  Future<void> createJob(JobModel job) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: _headers,
      body: jsonEncode(job.toJson()),
    );
    if (res.statusCode >= 400) {
      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    }
  }

  Future<JobModel?> getJobByJobId(String jobId) async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/jobs/by-jobid/$jobId'), headers: _headers);
    if (res.statusCode == 200) {
      return JobModel.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<void> updateJob(JobModel job) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/${job.jobId}'),
      headers: _headers,
      body: jsonEncode(job.toJson()),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to update job: ${res.body}');
    }
  }

  Future<void> updateJobStatus(String jobId, String status, {String? location, int? quantity, DateTime? extractionDate, DateTime? expectedExtractionDate, DateTime? extractionCompletedDate, DateTime? productionDate, DateTime? expectedProductionDate, String? inspectionReportNumber, String? invoiceNumber}) async {
    await _loadToken();
    final Map<String, dynamic> body = {
      'status': status,
    };
    if (location != null) body['currentLocation'] = location;
    if (quantity != null) body['deliveredQuantity'] = quantity;
    if (extractionDate != null) body['extractionDate'] = extractionDate.toIso8601String();
    if (expectedExtractionDate != null) body['expectedExtractionDate'] = expectedExtractionDate.toIso8601String();
    if (extractionCompletedDate != null) body['extractionCompletedDate'] = extractionCompletedDate.toIso8601String();
    if (productionDate != null) body['productionDate'] = productionDate.toIso8601String();
    if (expectedProductionDate != null) body['expectedProductionDate'] = expectedProductionDate.toIso8601String();
    if (inspectionReportNumber != null) body['inspectionReportNumber'] = inspectionReportNumber;
    if (invoiceNumber != null) body['invoiceNumber'] = invoiceNumber;
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/status'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to update status: ${res.body}');
    }
  }

  Future<void> forwardJob(String jobId, String nextSupplier) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/forward'),
      headers: _headers,
      body: jsonEncode({'nextSupplier': nextSupplier}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to forward job: ${res.body}');
    }
  }

  Future<void> returnPartialJob(String jobId, int returnQuantity) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/return-partial'),
      headers: _headers,
      body: jsonEncode({'returnQuantity': returnQuantity}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to process return: ${res.body}');
    }
  }

  Future<void> deleteJob(String jobId) async {
    await _loadToken();
    await http.delete(
      Uri.parse('$baseUrl/jobs/$jobId'),
      headers: _headers,
    );
  }

  Future<void> restoreJob(String jobId) async {
    await _loadToken();
    await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/restore'),
      headers: _headers,
    );
  }

  Future<void> undoJobStatus(String jobId) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/undo'),
      headers: _headers,
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to undo job: ${res.body}');
    }
  }

  Future<Map<String, dynamic>?> getDashboardMonthStats(String month) async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/dashboard/month/$month'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDashboardDateStats(String date) async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/dashboard/date/$date'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<List<JobModel>> getFilteredJobs({String? month, String? date, String? supplier, String? partNumber, String? status}) async {
    await _loadToken();
    
    final queryParams = <String, String>{};
    if (month != null && month.isNotEmpty) queryParams['month'] = month;
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (supplier != null && supplier.isNotEmpty) queryParams['supplier'] = supplier;
    if (partNumber != null && partNumber.isNotEmpty) queryParams['partNumber'] = partNumber;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    
    final uri = Uri.parse('$baseUrl/jobs/filter').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => _mapJob(d)).toList();
    } else {
      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    }
  }

  Future<List<JobModel>> searchJobs(String query) async {
    await _loadToken();
    final uri = Uri.parse('$baseUrl/jobs/search').replace(queryParameters: {'q': query});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => _mapJob(d)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getReadyForDelivery() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/jobs/ready-for-delivery'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> deliverPartial(String partNumber, int quantity) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/jobs/deliver-partial'),
      headers: _headers,
      body: jsonEncode({'partNumber': partNumber, 'deliveryQuantity': quantity}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to deliver: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> removeAggregatedParts(List<String> partNumbers) async {
    await _loadToken();
    await http.put(
      Uri.parse('$baseUrl/jobs/remove-aggregated'),
      headers: _headers,
      body: jsonEncode({'partNumbers': partNumbers}),
    );
  }

  Future<List<Map<String, dynamic>>> getStockSummary({String? month, String? date}) async {
    try {
      await _loadToken();
      if (_token == null) return [];
      
      String query = '';
      if (date != null) {
        query = '?date=$date';
      } else if (month != null) {
        query = '?month=$month';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/jobs/stock-summary$query'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Get stock summary error: $e');
      return [];
    }
  }

  JobModel _mapJob(Map<String, dynamic> data) {
    return JobModel.fromJson(data);
  }

  // --- BIN BOX BALANCES ---

  Future<List<BinBoxBalance>> getBinBoxBalances() async {
    await _loadToken();
    final response = await http.get(
      Uri.parse('$baseUrl/binbox/balances'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BinBoxBalance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bin box balances');
    }
  }

  Future<void> returnBinBox(String destinationName, int returnedBins, int returnedBoxes) async {
    await _loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/binbox/return'),
      headers: _headers,
      body: json.encode({
        'destinationName': destinationName,
        'returnedBins': returnedBins,
        'returnedBoxes': returnedBoxes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to log bin box return');
    }
  }

  Future<List<BinBoxReturn>> getBinBoxHistory({String? month}) async {
    await _loadToken();
    var url = '$baseUrl/binbox/history';
    if (month != null) {
      url += '?month=${Uri.encodeQueryComponent(month)}';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BinBoxReturn.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bin box history');
    }
  }

  Future<void> deleteBinBoxReturn(String id) async {
    await _loadToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/binbox/return/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete return');
    }
  }
  // --- LEADS & CRM ---

  Future<List<LeadModel>> getNewStatusLeads() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/leads/new-status'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => LeadModel.fromJson(d)).toList();
    }
    return [];
  }

  Future<List<LeadModel>> getDeclinedLeads() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/leads/declined'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => LeadModel.fromJson(d)).toList();
    }
    return [];
  }

  Future<LeadModel> createLead(LeadModel lead) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/leads'),
      headers: _headers,
      body: jsonEncode(lead.toJson()),
    );
    if (res.statusCode == 200) {
      return LeadModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to create lead');
    }
  }

  Future<LeadModel> updateLead(LeadModel lead) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/leads/${lead.id}'),
      headers: _headers,
      body: jsonEncode(lead.toJson()),
    );
    if (res.statusCode == 200) {
      return LeadModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to update lead');
    }
  }

  Future<List<String>> getWorkers() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/jobs/workers'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<String>();
    }
    return [];
  }
  Future<List<Map<String, dynamic>>> getMasterData() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/master-data'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<void> deleteMasterData(String id) async {
    await _loadToken();
    final res = await http.delete(Uri.parse('$baseUrl/master-data/$id'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to delete master data');
    }
  }

  Future<void> createSpare(String partNumber, int quantity, String? description, String? gritSize, String? sourceJobId, String? jobType, String? personResponsible, String? expectedCompletionDate) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/spares'),
      headers: _headers,
      body: jsonEncode({
        'partNumber': partNumber,
        'quantity': quantity,
        'description': description,
        'gritSize': gritSize,
        'sourceJobId': sourceJobId,
        'jobType': jobType,
        'personResponsible': personResponsible,
        'expectedCompletionDate': expectedCompletionDate,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to create spare');
  }

  Future<List<Map<String, dynamic>>> getSpares() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/spares'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<void> deleteSpare(String id) async {
    await _loadToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/spares/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to delete spare');
  }

  Future<void> updateSpareStatus(String id, String status) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/spares/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> undoSendToSpare(String jobId) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/spares/undo-send'),
      headers: _headers,
      body: jsonEncode({'jobId': jobId}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> consumeSpare(String spareId, int quantity, String targetJobId) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/spares/$spareId/consume'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity, 'targetJobId': targetJobId}),
    );
    if (res.statusCode != 200) throw Exception('Failed to consume spare');
  }
}
