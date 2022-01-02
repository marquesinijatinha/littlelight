import 'dart:async';

import 'package:bungie_api/enums/destiny_component_type.dart';
import 'package:bungie_api/models/destiny_item_instance_component.dart';
import 'package:bungie_api/models/destiny_item_plug_base.dart';
import 'package:bungie_api/models/destiny_item_socket_state.dart';
import 'package:bungie_api/models/destiny_vendor_category.dart';
import 'package:bungie_api/models/destiny_vendor_component.dart';
import 'package:bungie_api/models/destiny_vendor_group.dart';
import 'package:bungie_api/models/destiny_vendor_sale_item_component.dart';
import 'package:bungie_api/models/destiny_vendors_response.dart';
import 'package:little_light/services/bungie_api/bungie_api.consumer.dart';
import 'package:little_light/services/storage/export.dart';

const _vendorComponents = [
  DestinyComponentType.ItemInstances,
  DestinyComponentType.ItemSockets,
  DestinyComponentType.ItemReusablePlugs,
  DestinyComponentType.Vendors,
  DestinyComponentType.VendorCategories,
  DestinyComponentType.VendorSales,
];

class VendorsService with StorageConsumer, BungieApiConsumer {
  static final VendorsService _singleton = new VendorsService._internal();
  DateTime lastUpdated;
  factory VendorsService() {
    return _singleton;
  }
  VendorsService._internal();

  Map<String, DestinyVendorsResponse> _vendors = {};

  Future<Map<String, DestinyVendorComponent>> getVendors(
      String characterId) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    return vendors?.vendors?.data;
  }

  Future<List<DestinyVendorCategory>> getVendorCategories(
      String characterId, int vendorHash) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    return vendors?.categories?.data["$vendorHash"]?.categories;
  }

  Future<List<DestinyVendorGroup>> getVendorGroups(String characterId) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    return vendors?.vendorGroups?.data?.groups;
  }

  Future<List<DestinyItemSocketState>> getSaleItemSockets(
      String characterId, int vendorHash, int index) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    try {
      return vendors
          ?.itemComponents["$vendorHash"].sockets.data["$index"].sockets;
    } catch (e) {}
    return null;
  }

  Future<Map<String, List<DestinyItemPlugBase>>> getSaleItemReusablePerks(
      String characterId, int vendorHash, int index) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    try {
      return vendors
          .itemComponents["$vendorHash"].reusablePlugs.data["$index"]?.plugs;
    } catch (e) {}
    return null;
  }

  Future<DestinyItemInstanceComponent> getSaleItemInstanceInfo(
      String characterId, int vendorHash, int index) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    try {
      return vendors?.itemComponents["$vendorHash"].instances.data["$index"];
    } catch (e) {}
    return null;
  }

  Future<Map<String, DestinyVendorSaleItemComponent>> getVendorSales(
      String characterId, int vendorHash) async {
    var vendors = await _getVendorsDataForCharacter(characterId);
    return vendors?.sales?.data["$vendorHash"]?.saleItems;
  }

  Future<DestinyVendorsResponse> _getVendorsDataForCharacter(String characterId) async {
    if (!_vendors.containsKey(characterId)) {
      _vendors[characterId] =
          await bungieAPI.getVendors(_vendorComponents, characterId);
    }
    return _vendors[characterId];
  }

  Future<Map<String, DestinyVendorsResponse>> fetchVendorData() async {
    try {
      Map<String, DestinyVendorsResponse> res = await _updateVendorsData();
      currentMembershipStorage.saveCachedVendors(_vendors);
      return res;
    } catch (e) {}
    return _vendors;
  }

  Future<Map<String, DestinyVendorsResponse>> _updateVendorsData() async {
    Map<String, DestinyVendorsResponse> response = {};

    return response;
  }
}
