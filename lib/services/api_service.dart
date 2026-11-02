import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import '../models/company_storage.dart';
import '../models/supplier_model.dart';
import '../models/user_model.dart';
import '../models/bin_box_balance_model.dart';
import '../models/bin_box_return_model.dart';
import '../models/notification_model.dart';
import '../models/lead_model.dart';
import '../models/raw_material_model.dart';
import '../models/item_database_model.dart';
import '../models/estimate_model.dart';
import '../models/delivery_challan_model.dart';
import '../models/attendance_model.dart';
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
    final prefs = await SharedPreferences.getInstance();
    _token ??= prefs.getString('auth_token');
    
    if (currentUser == null) {
      final roleStr = prefs.getString('auth_role');
      if (roleStr != null) {
        UserRole r = UserRole.employee;
        if (roleStr == 'owner') {
          r = UserRole.owner;
        } else if (roleStr == 'admin') {
          r = UserRole.admin;
        } else if (roleStr == 'employee1') {
          r = UserRole.employee1;
        } else if (roleStr == 'employee2') {
          r = UserRole.employee2;
        } else if (roleStr == 'employee3') {
          r = UserRole.employee3;
        } else if (roleStr == 'payroll') {
          r = UserRole.payroll;
        }

        currentUser = UserModel(
          email: prefs.getString('auth_email') ?? '',
          password: '',
          role: r,
        );
      }
    }
  }

  Future<void> ensureInitialized() async {
    await _loadToken();
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
        if (_token != null) {
          await prefs.setString('auth_token', _token!);
        }
        final roleStr = data['role'] ?? 'employee';
        await prefs.setString('auth_role', roleStr);
        await prefs.setString('auth_email', data['email']);
        
        UserRole r = UserRole.employee;
        if (roleStr == 'owner') {
          r = UserRole.owner;
        } else if (roleStr == 'admin') {
          r = UserRole.admin;
        } else if (roleStr == 'employee1') {
          r = UserRole.employee1;
        } else if (roleStr == 'employee2') {
          r = UserRole.employee2;
        } else if (roleStr == 'employee3') {
          r = UserRole.employee3;
        } else if (roleStr == 'payroll') {
          r = UserRole.payroll;
        }

        currentUser = UserModel(
          email: data['email'],
          password: '',
          role: r,
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
      return data.map((json) {
        return SupplierModel(
          supplierId: json['_id'],
          supplierName: json['supplierName'],
        );
      }).toList();
    } else {
      throw Exception('Failed to load suppliers');
    }
  }

  Future<List<SupplierModel>> getSpareSuppliers() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/spare-suppliers'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((json) {
        return SupplierModel(
          supplierId: json['_id'],
          supplierName: json['supplierName'],
        );
      }).toList();
    } else {
      throw Exception('Failed to load spare suppliers');
    }
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
    if (res.statusCode != 200) {
      throw Exception('Failed to delete supplier');
    }
  }

  Future<void> updateSupplier(String supplierId, String newName) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/suppliers/$supplierId'),
      headers: _headers,
      body: jsonEncode({'supplierName': newName}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update supplier');
    }
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

  Future<void> grantJobAccess(String jobId) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/grant-access'),
      headers: _headers,
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to grant job access: ${res.body}');
    }
  }

  Future<void> rejectJob(String jobId) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/reject'),
      headers: _headers,
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to reject job: ${res.body}');
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

  Future<void> forwardJob(String jobId, String nextSupplier, {int? forwardQuantity, String? deliveryChalanNumber, DateTime? deliveryChalanDate}) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/forward'),
      headers: _headers,
      body: jsonEncode({
        'nextSupplier': nextSupplier,
        'forwardQuantity': forwardQuantity,
        'deliveryChalanNumber': deliveryChalanNumber,
        'deliveryChalanDate': deliveryChalanDate?.toIso8601String(),
      }),
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
      if (_token == null) {
      return [];
    }
      
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
    if (res.statusCode >= 400) {
      throw Exception('Failed to delete master data: ${res.body}');
    }
  }

  Future<void> saveMasterData(String jobType, String field, String value) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/master-data'),
      headers: _headers,
      body: jsonEncode({
        'jobType': jobType,
        'field': field,
        'value': value,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to save master data: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> createSpare(String partNumber, int quantity, String? description, String? gritSize, String? sourceJobId, String? jobType, String? personResponsible, String? expectedCompletionDate) async {
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
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to create spare');
    }
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
    if (res.statusCode != 200) {
      throw Exception('Failed to delete spare');
    }
  }

  Future<void> createJobFromSpareToDelivery(String spareId, Map<String, dynamic> payload) async {
    await _loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/spares/$spareId/to-ready-delivery'),
      headers: _headers,
      body: json.encode(payload),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to move spare to ready for delivery');
    }
  }

  Future<void> createJobFromSpareToProduction(String spareId, Map<String, dynamic> payload) async {
    await _loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/spares/$spareId/to-production'),
      headers: _headers,
      body: json.encode(payload),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to move spare to production');
    }
  }

  Future<void> addSpareSupplier(String name) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/spare-suppliers'),
      headers: _headers,
      body: jsonEncode({'supplierName': name}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to add spare supplier');
    }
  }

  // Update Spare to Extraction
  Future<void> updateSpareToExtraction(String spareId, Map<String, dynamic> data) async {
    await _loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/spares/$spareId/to-extraction'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update spare to extraction stage');
    }
  }

  // Update Spare to Production Stage
  Future<void> updateSpareToProductionStage(String spareId, Map<String, dynamic> data) async {
    await _loadToken();
    final response = await http.put(
      Uri.parse('$baseUrl/spares/$spareId/to-production-stage'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update spare to production stage');
    }
  }

  Future<void> deleteSpareSupplier(String id) async {
    await _loadToken();
    final res = await http.delete(Uri.parse('$baseUrl/spare-suppliers/$id'), headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to delete spare supplier');
    }
  }

  Future<void> updateSpare(String id, {String? status, String? currentSupplier}) async {
    await _loadToken();
    final Map<String, dynamic> body = {};
    if (status != null) body['status'] = status;
    if (currentSupplier != null) body['currentSupplier'] = currentSupplier;

    final res = await http.put(
      Uri.parse('$baseUrl/spares/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update spare');
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

  Future<void> undoSpareStatus(String spareId) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/spares/$spareId/undo'),
      headers: {'x-auth-token': _token!},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to undo spare: ${res.body}');
    }
  }

  Future<void> consumeSpare(String spareId, int quantity, String targetJobId) async {
    await _loadToken();
    final res = await http.put(
      Uri.parse('$baseUrl/spares/$spareId/consume'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity, 'targetJobId': targetJobId}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to consume spare');
    }
  }

  // --- Raw Materials ---
  Future<List<RawMaterialModel>> getRawMaterials() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$baseUrl/raw-materials'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((d) => RawMaterialModel.fromJson(d)).toList();
    }
    return [];
  }

  Future<RawMaterialModel> addRawMaterial(RawMaterialModel rawMaterial) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/raw-materials'),
      headers: _headers,
      body: jsonEncode(rawMaterial.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return RawMaterialModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to add raw material: ${res.body}');
  }

  Future<void> deleteRawMaterial(String id) async {
    await _loadToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/raw-materials/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete raw material: ${res.body}');
    }
  }

  Future<void> useRawMaterial(String id, double quantity) async {
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/raw-materials/$id/use'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to use raw material: ${res.body}');
    }
  }

  Future<List<ItemDatabaseModel>> getDatabaseItems([String search = '']) async {
    await _loadToken();
    final url = search.isNotEmpty 
        ? '$baseUrl/item-database?search=${Uri.encodeComponent(search)}'
        : '$baseUrl/item-database';
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => ItemDatabaseModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch database items');
    }
  }

  Future<void> saveToItemDatabase(String itemName, String? description) async {
    if (itemName.trim().isEmpty) return;
    await _loadToken();
    final res = await http.post(
      Uri.parse('$baseUrl/item-database'),
      headers: _headers,
      body: jsonEncode({
        'itemName': itemName.trim(),
        'description': description?.trim() ?? '',
      }),
    );
    if (res.statusCode != 200) {
      debugPrint('Failed to save item to database: ${res.body}');
    }
  }

  Future<void> fetchAndMergeDynamicCompanies() async {
    await _loadToken();
    try {
      final res = await http.get(Uri.parse('$baseUrl/companies'), headers: _headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final dynamicCompanies = data.map((e) => CompanyStorage.fromJson(e)).toList();
        mergeDynamicCompanies(dynamicCompanies);
      }
    } catch (e) {
      debugPrint('Error fetching companies: $e');
    }
  }

  Future<void> createCompanyStorage(String name, String prefix) async {
    if (name.trim().isEmpty) return;
    await _loadToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/companies'),
        headers: _headers,
        body: jsonEncode({
          'name': name.trim(),
          'prefixes': [prefix.trim().toUpperCase()]
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        mergeDynamicCompanies([CompanyStorage.fromJson(data)]);
      }
    } catch (e) {
      debugPrint('Error creating company: $e');
    }
  }

  Future<bool> deleteCompanyStorage(String name) async {
    if (name.trim().isEmpty) return false;
    await _loadToken();
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/companies/${Uri.encodeComponent(name.trim())}'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        removeCompanyFromStorage(name.trim());
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting company: $e');
    }
    return false;
  }

  Future<bool> deleteDatabaseItem(String identifier) async {
    if (identifier.trim().isEmpty) return false;
    await _loadToken();
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/item-database/${Uri.encodeComponent(identifier.trim())}'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting database item: $e');
      return false;
    }
  }

  Future<bool> bulkDeleteDatabaseItems({List<String>? ids, List<String>? names}) async {
    await _loadToken();
    try {
      final payload = <String, dynamic>{};
      if (ids != null) payload['ids'] = ids;
      if (names != null) payload['names'] = names;
      final res = await http.post(
        Uri.parse('$baseUrl/item-database/bulk-delete'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error bulk deleting database items: $e');
      return false;
    }
  }

  // --- Estimates API ---
  Future<List<EstimateModel>> getEstimates({String? jobId, String? search}) async {
    await _loadToken();
    try {
      final queryParams = <String, String>{};
      if (jobId != null && jobId.isNotEmpty) queryParams['jobId'] = jobId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/estimates').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => EstimateModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching estimates: $e');
    }
    return [];
  }

  Future<EstimateModel?> getEstimateByJobId(String jobId) async {
    await _loadToken();
    try {
      final res = await http.get(Uri.parse('$baseUrl/estimates/job/$jobId'), headers: _headers);
      if (res.statusCode == 200) {
        return EstimateModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching estimate by jobId: $e');
    }
    return null;
  }

  Future<EstimateModel?> getEstimateById(String id) async {
    await _loadToken();
    try {
      final res = await http.get(Uri.parse('$baseUrl/estimates/$id'), headers: _headers);
      if (res.statusCode == 200) {
        return EstimateModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching estimate by id: $e');
    }
    return null;
  }

  Future<EstimateModel> saveEstimate(EstimateModel estimate) async {
    await _loadToken();
    if (estimate.id != null && estimate.id!.isNotEmpty) {
      // Update
      final res = await http.put(
        Uri.parse('$baseUrl/estimates/${estimate.id}'),
        headers: _headers,
        body: jsonEncode(estimate.toJson()),
      );
      if (res.statusCode == 200) {
        return EstimateModel.fromJson(jsonDecode(res.body));
      }
      throw Exception('Failed to update estimate: ${res.body}');
    } else {
      // Create
      final res = await http.post(
        Uri.parse('$baseUrl/estimates'),
        headers: _headers,
        body: jsonEncode(estimate.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return EstimateModel.fromJson(jsonDecode(res.body));
      }
      throw Exception('Failed to create estimate: ${res.body}');
    }
  }

  Future<bool> deleteEstimate(String id) async {
    await _loadToken();
    try {
      final res = await http.delete(Uri.parse('$baseUrl/estimates/$id'), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting estimate: $e');
      return false;
    }
  }

  Future<List<EstimateModel>> autoSyncRepeatEstimates() async {
    await _loadToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/estimates/auto-sync-repeats'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['created'] is List) {
          return (data['created'] as List)
              .map((e) => EstimateModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error auto-syncing repeat estimates: $e');
    }
    return [];
  }

  // --- DELIVERY CHALLANS (DC) ---

  Future<String> getNextDeliveryChallanNumber() async {
    await _loadToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/delivery-challans/next-number'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['nextDcNumber'] != null) {
          return data['nextDcNumber'].toString();
        }
      }
    } catch (e) {
      debugPrint('Error getting next DC number: $e');
    }
    return 'DC2627-00232';
  }

  Future<List<DeliveryChallanModel>> getDeliveryChallans({
    String? supplier,
    String? jobId,
    String? search,
  }) async {
    await _loadToken();
    try {
      final queryParams = <String, String>{};
      if (supplier != null && supplier.isNotEmpty) queryParams['supplier'] = supplier;
      if (jobId != null && jobId.isNotEmpty) queryParams['jobId'] = jobId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/delivery-challans')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => DeliveryChallanModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching delivery challans: $e');
    }
    return [];
  }

  Future<List<DeliveryChallanModel>> getDeliveryChallansForJob(String jobId) async {
    await _loadToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/delivery-challans/job/$jobId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => DeliveryChallanModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching delivery challans for job $jobId: $e');
    }
    return [];
  }

  Future<DeliveryChallanModel?> getDeliveryChallanById(String id) async {
    await _loadToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/delivery-challans/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return DeliveryChallanModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching delivery challan by id: $e');
    }
    return null;
  }

  Future<DeliveryChallanModel> saveDeliveryChallan(DeliveryChallanModel challan) async {
    await _loadToken();
    if (challan.id != null && challan.id!.isNotEmpty) {
      // Update
      final res = await http.put(
        Uri.parse('$baseUrl/delivery-challans/${challan.id}'),
        headers: _headers,
        body: jsonEncode(challan.toJson()),
      );
      if (res.statusCode == 200) {
        return DeliveryChallanModel.fromJson(jsonDecode(res.body));
      }
      throw Exception('Failed to update delivery challan: ${res.body}');
    } else {
      // Create
      final res = await http.post(
        Uri.parse('$baseUrl/delivery-challans'),
        headers: _headers,
        body: jsonEncode(challan.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return DeliveryChallanModel.fromJson(jsonDecode(res.body));
      }
      throw Exception('Failed to create delivery challan: ${res.body}');
    }
  }

  Future<bool> deleteDeliveryChallan(String id) async {
    await _loadToken();
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/delivery-challans/$id'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting delivery challan: $e');
      return false;
    }
  }

  // --- Attendance & Face Recognition Methods ---

  Future<List<EnrolledEmployeeModel>> getEnrolledEmployees() async {
    await _loadToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/attendance/enrolled-employees'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((json) => EnrolledEmployeeModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching enrolled employees: $e');
    }
    return [];
  }

  Future<bool> enrollEmployeeFace({
    required String email,
    required List<double> faceEmbeddings,
    String? facePhotoUrl,
    String? name,
    String? department,
  }) async {
    await _loadToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/attendance/enroll-face'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'faceEmbeddings': faceEmbeddings,
          'facePhotoUrl': facePhotoUrl,
          'name': name,
          'department': department,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error enrolling face: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> recordAttendanceScan({
    required String email,
    String scanType = 'auto',
    String scanMethod = 'face_recognition',
    String? notes,
  }) async {
    await _loadToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/attendance/scan'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'scanType': scanType,
          'scanMethod': scanMethod,
          'notes': notes,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final err = jsonDecode(res.body);
        return {
          'success': false,
          'error': err['error'] ?? 'Scan failed with status ${res.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error recording attendance scan: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyCameraFrame({
    required String imageBase64,
    String scanType = 'auto',
    String? notes,
  }) async {
    await _loadToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/attendance/verify-camera-frame'),
        headers: _headers,
        body: jsonEncode({
          'image': imageBase64,
          'scanType': scanType,
          'notes': notes,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final err = jsonDecode(res.body);
        return {
          'success': false,
          'error': err['error'] ?? 'Face verification failed with status ${res.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error verifying camera frame: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<AttendanceModel>> getTodayAttendance() async {
    await _loadToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/attendance/today'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((j) => AttendanceModel.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching today attendance: $e');
    }
    return [];
  }

  Future<List<AttendanceModel>> getAttendanceHistory({
    String? date,
    String? month,
    String? email,
  }) async {
    await _loadToken();
    try {
      final params = <String, String>{};
      if (date != null) params['date'] = date;
      if (month != null) params['month'] = month;
      if (email != null) params['email'] = email;

      final uri = Uri.parse('$baseUrl/attendance/history').replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((j) => AttendanceModel.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
    }
    return [];
  }

  Future<List<MonthlyAttendanceSummary>> getAttendanceSummary({String? month}) async {
    await _loadToken();
    try {
      final uri = Uri.parse('$baseUrl/attendance/summary').replace(
        queryParameters: month != null ? {'month': month} : null,
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> summaryList = data['summary'] ?? [];
        return summaryList.map((j) => MonthlyAttendanceSummary.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching attendance summary: $e');
    }
    return [];
  }

  Future<bool> deleteAttendanceRecord(String id) async {
    await _loadToken();
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/attendance/$id'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting attendance record: $e');
      return false;
    }
  }
}
