import 'customer_model.dart';

class CustomerRemoteModel {
  final String id;
  final String customerCode;
  final String name;
  final String? birthDay;
  final String? groupName;
  final String? groupId;
  final String address;
  final String tel;
  final String email;
  final String? description;
  final String? location;
  final String? district;
  final String? avatar;
  final double totalMoney;
  final String? managerBy;
  final String? taxCode;
  final bool isCustomer;
  final bool isSupplier;
  final double? longitude;
  final double? latitude;

  CustomerRemoteModel({
    required this.id,
    required this.customerCode,
    required this.name,
    this.birthDay,
    this.groupName,
    this.groupId,
    required this.address,
    required this.tel,
    required this.email,
    this.description,
    this.location,
    this.district,
    this.avatar,
    required this.totalMoney,
    this.managerBy,
    this.taxCode,
    required this.isCustomer,
    required this.isSupplier,
    this.longitude,
    this.latitude,
  });

  factory CustomerRemoteModel.fromJson(Map<String, dynamic> json) {
    return CustomerRemoteModel(
      id: json['Id'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      name: json['Name'] ?? '',
      birthDay: json['BirthDay'],
      groupName: json['GroupName'],
      groupId: json['GroupId'],
      address: json['Address'] ?? '',
      tel: json['Tel'] ?? '',
      email: json['Email'] ?? '',
      description: json['Description'],
      location: json['Location'],
      district: json['District'],
      avatar: json['Avatar'],
      totalMoney: json['TotalMoney']?.toDouble() ?? 0.0,
      managerBy: json['ManagerBy'],
      taxCode: json['TaxCode'],
      isCustomer: json['IsCustomer'] ?? true,
      isSupplier: json['IsSupplier'] ?? false,
      longitude: json['Longitude']?.toDouble(),
      latitude: json['Latitude']?.toDouble(),
    );
  }

  // Convert to domain entity
  CustomerModel toCustomerModel() {
    CustomerGroupModel? group;
    if (groupId != null && groupName != null) {
      group = CustomerGroupModel(
        id: int.tryParse(groupId!) ?? 0,
        uuid: groupId,
        name: groupName!,
      );
    }

    return CustomerModel(
      id: int.tryParse(id) ?? 0,
      uuid: id, // Store UUID string from API (Id field: "7c8880ec-900b-424e-851a-4a995402b1f2")
      name: name,
      phone: tel,
      address: address,
      note: description,
      group: group,
      createdAt: birthDay != null ? DateTime.parse(birthDay!) : DateTime.now(),
    );
  }
}

class CustomerResponseModel {
  final List<CustomerRemoteModel> data;
  final PagingModel paging;
  final MetaModel meta;

  CustomerResponseModel({
    required this.data,
    required this.paging,
    required this.meta,
  });

  factory CustomerResponseModel.fromJson(Map<String, dynamic> json) {
    return CustomerResponseModel(
      data: (json['data'] as List).map((item) => CustomerRemoteModel.fromJson(item)).toList(),
      paging: PagingModel.fromJson(json['paging']),
      meta: MetaModel.fromJson(json['meta']),
    );
  }
}

class PagingModel {
  final int totalPage;
  final int pageIndex;
  final int pageSize;
  final int totalCount;

  PagingModel({
    required this.totalPage,
    required this.pageIndex,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagingModel.fromJson(Map<String, dynamic> json) {
    return PagingModel(
      totalPage: json['TotalPage'] ?? 0,
      pageIndex: json['PageIndex'] ?? 0,
      pageSize: json['PageSize'] ?? 0,
      totalCount: json['TotalCount'] ?? 0,
    );
  }
}

class MetaModel {
  final int statusCode;
  final String message;

  MetaModel({
    required this.statusCode,
    required this.message,
  });

  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

// Customer Group Remote Model
class CustomerGroupRemoteModel {
  final String id;
  final String groupCode;
  final String groupName;
  final String description;

  CustomerGroupRemoteModel({
    required this.id,
    required this.groupCode,
    required this.groupName,
    required this.description,
  });

  factory CustomerGroupRemoteModel.fromJson(Map<String, dynamic> json) {
    return CustomerGroupRemoteModel(
      id: json['Id'] ?? '',
      groupCode: json['GroupCode'] ?? '',
      groupName: json['GroupName'] ?? '',
      description: json['Description'] ?? '',
    );
  }

  // Convert to domain entity
  CustomerGroupModel toCustomerGroupModel() {
    return CustomerGroupModel(
      id: id.hashCode, // Use hashCode as int id for backward compatibility
      uuid: id, // Store UUID string (Id from API)
      groupCode: groupCode, // GroupCode from API
      name: groupName, // GroupName from API
      description: description.isNotEmpty ? description : null,
    );
  }
}

class CustomerGroupResponseModel {
  final List<CustomerGroupRemoteModel> data;
  final MetaModel meta;

  CustomerGroupResponseModel({
    required this.data,
    required this.meta,
  });

  factory CustomerGroupResponseModel.fromJson(Map<String, dynamic> json) {
    return CustomerGroupResponseModel(
      data: (json['data'] as List).map((item) => CustomerGroupRemoteModel.fromJson(item)).toList(),
      meta: MetaModel.fromJson(json['meta']),
    );
  }
}
