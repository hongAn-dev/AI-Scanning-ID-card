class ApiConstants {
  static const String baseUrl = 'http://api.masterpro.vn/';

  // Endpoints
  static const String loginEndpoint = 'token';
  static const String usersEndpoint = '/users';
  static const String postsEndpoint = '/posts';
  static const String customersEndpoint = 'api/Category/CustomerList';
  static const String customerGroupsEndpoint = 'api/Category/LocationList';
  static const String getNewCustomerCodeEndpoint =
      'api/Category/GetNewCustomerCode';
  static const String addNewCustomerByCCCDEndpoint =
      'api/Category/AddNewCustomerByCCCD';
  static const String updateCustomerEndpoint = 'api/Category/UpdateCustomer';
  static const String deleteCustomerEndpoint = 'api/Category/DeleteCustomer';
  static const String changePasswordEndpoint = 'api/Tenant/ChangePwd';

  // Timeouts
  static const int connectionTimeout = 120000; // 120 seconds (2 minutes)
  static const int receiveTimeout = 120000; // 120 seconds (2 minutes)
}
