class ApiConstants {
  static const String baseUrl = 'http://api.masterpro.vn/';

  // Endpoints
  static const String loginEndpoint = 'token';
  static const String usersEndpoint = '/users';
  static const String postsEndpoint = '/posts';
  static const String productsEndpoint = 'api/Category/ProductListV2';
  static const String productDetailEndpoint = 'api/Category/GetProductInfo';
  static const String productGroupsEndpoint = 'api/Category/ProductGroupList';
  static const String customersEndpoint = 'api/Category/CustomerList';
  static const String customerGroupsEndpoint = 'api/Category/CustomerGroupList';
  static const String getNewCustomerCodeEndpoint = 'api/Category/GetNewCustomerCode';
  static const String addNewCustomerEndpoint = 'api/Category/AddNewCustomer';
  static const String orderHistoryEndpoint = 'api/PurchaseOrder/PurchaseOrderList';
  static const String orderDetailEndpoint = 'api/PurchaseOrder/GetPurchaseOrderDetail';
  static const String getNewOrderCodeEndpoint = "api/PurchaseOrder/GetNewCode/CNT";
  static const String createOrderEndpoint = 'api/PurchaseOrder/AddNewPurchaseOrder';
  static const String changePasswordEndpoint = 'api/Tenant/ChangePwd';

  // Timeouts
  static const int connectionTimeout = 120000; // 120 seconds (2 minutes)
  static const int receiveTimeout = 120000; // 120 seconds (2 minutes)
}
