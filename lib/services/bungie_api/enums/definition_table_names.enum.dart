//@dart=2.12
import 'package:bungie_api/destiny2.dart';

typedef dynamic DefinitionTableIdentityFunction(Map<String, dynamic> json);

class DefinitionTableNames {
  static Map<Type, DefinitionTableIdentityFunction> identities = {
    DestinyPlaceDefinition: (json) => DestinyPlaceDefinition.fromJson(json),
    DestinyActivityDefinition: (json) =>
        DestinyActivityDefinition.fromJson(json),
    DestinyActivityTypeDefinition: (json) =>
        DestinyActivityTypeDefinition.fromJson(json),
    DestinyClassDefinition: (json) => DestinyClassDefinition.fromJson(json),
    DestinyGenderDefinition: (json) => DestinyGenderDefinition.fromJson(json),
    DestinyInventoryBucketDefinition: (json) =>
        DestinyInventoryBucketDefinition.fromJson(json),
    DestinyRaceDefinition: (json) => DestinyRaceDefinition.fromJson(json),
    DestinyTalentGridDefinition: (json) =>
        DestinyTalentGridDefinition.fromJson(json),
    DestinyUnlockDefinition: (json) => DestinyUnlockDefinition.fromJson(json),
    DestinyMaterialRequirementSetDefinition: (json) =>
        DestinyMaterialRequirementSetDefinition.fromJson(json),
    DestinySandboxPerkDefinition: (json) =>
        DestinySandboxPerkDefinition.fromJson(json),
    DestinyStatGroupDefinition: (json) =>
        DestinyStatGroupDefinition.fromJson(json),
    DestinyFactionDefinition: (json) => DestinyFactionDefinition.fromJson(json),
    DestinyVendorGroupDefinition: (json) =>
        DestinyVendorGroupDefinition.fromJson(json),
    DestinyRewardSourceDefinition: (json) =>
        DestinyRewardSourceDefinition.fromJson(json),
    DestinyItemCategoryDefinition: (json) =>
        DestinyItemCategoryDefinition.fromJson(json),
    DestinyDamageTypeDefinition: (json) =>
        DestinyDamageTypeDefinition.fromJson(json),
    DestinyActivityModeDefinition: (json) =>
        DestinyActivityModeDefinition.fromJson(json),
    DestinyActivityGraphDefinition: (json) =>
        DestinyActivityGraphDefinition.fromJson(json),
    DestinyCollectibleDefinition: (json) =>
        DestinyCollectibleDefinition.fromJson(json),
    DestinyStatDefinition: (json) => DestinyStatDefinition.fromJson(json),
    DestinyItemTierTypeDefinition: (json) =>
        DestinyItemTierTypeDefinition.fromJson(json),
    DestinyPresentationNodeDefinition: (json) =>
        DestinyPresentationNodeDefinition.fromJson(json),
    DestinyRecordDefinition: (json) => DestinyRecordDefinition.fromJson(json),
    DestinyDestinationDefinition: (json) =>
        DestinyDestinationDefinition.fromJson(json),
    DestinyEquipmentSlotDefinition: (json) =>
        DestinyEquipmentSlotDefinition.fromJson(json),
    DestinyInventoryItemDefinition: (json) =>
        DestinyInventoryItemDefinition.fromJson(json),
    DestinyLocationDefinition: (json) =>
        DestinyLocationDefinition.fromJson(json),
    DestinyLoreDefinition: (json) => DestinyLoreDefinition.fromJson(json),
    DestinyObjectiveDefinition: (json) =>
        DestinyObjectiveDefinition.fromJson(json),
    DestinyProgressionDefinition: (json) =>
        DestinyProgressionDefinition.fromJson(json),
    DestinyProgressionLevelRequirementDefinition: (json) =>
        DestinyProgressionLevelRequirementDefinition.fromJson(json),
    DestinySocketCategoryDefinition: (json) =>
        DestinySocketCategoryDefinition.fromJson(json),
    DestinySocketTypeDefinition: (json) =>
        DestinySocketTypeDefinition.fromJson(json),
    DestinyVendorDefinition: (json) => DestinyVendorDefinition.fromJson(json),
    DestinyMilestoneDefinition: (json) =>
        DestinyMilestoneDefinition.fromJson(json),
    DestinyActivityModifierDefinition: (json) =>
        DestinyActivityModifierDefinition.fromJson(json),
    DestinyReportReasonCategoryDefinition: (json) =>
        DestinyReportReasonCategoryDefinition.fromJson(json),
    DestinyPlugSetDefinition: (json) => DestinyPlugSetDefinition.fromJson(json),
    DestinyChecklistDefinition: (json) =>
        DestinyChecklistDefinition.fromJson(json),
    DestinyHistoricalStatsDefinition: (json) =>
        DestinyHistoricalStatsDefinition.fromJson(json),
    DestinyMilestoneRewardEntryDefinition: (json) =>
        DestinyMilestoneRewardEntryDefinition.fromJson(json),
    DestinyEnergyTypeDefinition: (json) =>
        DestinyEnergyTypeDefinition.fromJson(json),
    DestinySeasonDefinition: (json) => DestinySeasonDefinition.fromJson(json),
    DestinySeasonPassDefinition: (json) =>
        DestinySeasonPassDefinition.fromJson(json),
    DestinyPowerCapDefinition: (json) =>
        DestinyPowerCapDefinition.fromJson(json),
    DestinyMetricDefinition: (json) => DestinyMetricDefinition.fromJson(json),
    DestinyTraitDefinition: (json) => DestinyTraitDefinition.fromJson(json)
  };

  static Map<Type, String> fromClass = {
    DestinyPlaceDefinition: "DestinyPlaceDefinition",
    DestinyActivityDefinition: "DestinyActivityDefinition",
    DestinyActivityTypeDefinition: "DestinyActivityTypeDefinition",
    DestinyClassDefinition: "DestinyClassDefinition",
    DestinyGenderDefinition: "DestinyGenderDefinition",
    DestinyInventoryBucketDefinition: "DestinyInventoryBucketDefinition",
    DestinyRaceDefinition: "DestinyRaceDefinition",
    DestinyTalentGridDefinition: "DestinyTalentGridDefinition",
    DestinyUnlockDefinition: "DestinyUnlockDefinition",
    DestinyMaterialRequirementSetDefinition:
        "DestinyMaterialRequirementSetDefinition",
    DestinySandboxPerkDefinition: "DestinySandboxPerkDefinition",
    DestinyStatGroupDefinition: "DestinyStatGroupDefinition",
    DestinyFactionDefinition: "DestinyFactionDefinition",
    DestinyVendorGroupDefinition: "DestinyVendorGroupDefinition",
    DestinyRewardSourceDefinition: "DestinyRewardSourceDefinition",
    DestinyItemCategoryDefinition: "DestinyItemCategoryDefinition",
    DestinyDamageTypeDefinition: "DestinyDamageTypeDefinition",
    DestinyActivityModeDefinition: "DestinyActivityModeDefinition",
    DestinyActivityGraphDefinition: "DestinyActivityGraphDefinition",
    DestinyCollectibleDefinition: "DestinyCollectibleDefinition",
    DestinyStatDefinition: "DestinyStatDefinition",
    DestinyItemTierTypeDefinition: "DestinyItemTierTypeDefinition",
    DestinyPresentationNodeDefinition: "DestinyPresentationNodeDefinition",
    DestinyRecordDefinition: "DestinyRecordDefinition",
    DestinyDestinationDefinition: "DestinyDestinationDefinition",
    DestinyEquipmentSlotDefinition: "DestinyEquipmentSlotDefinition",
    DestinyInventoryItemDefinition: "DestinyInventoryItemDefinition",
    DestinyLocationDefinition: "DestinyLocationDefinition",
    DestinyLoreDefinition: "DestinyLoreDefinition",
    DestinyObjectiveDefinition: "DestinyObjectiveDefinition",
    DestinyProgressionDefinition: "DestinyProgressionDefinition",
    DestinyProgressionLevelRequirementDefinition:
        "DestinyProgressionLevelRequirementDefinition",
    DestinySocketCategoryDefinition: "DestinySocketCategoryDefinition",
    DestinySocketTypeDefinition: "DestinySocketTypeDefinition",
    DestinyVendorDefinition: "DestinyVendorDefinition",
    DestinyMilestoneDefinition: "DestinyMilestoneDefinition",
    DestinyActivityModifierDefinition: "DestinyActivityModifierDefinition",
    DestinyReportReasonCategoryDefinition:
        "DestinyReportReasonCategoryDefinition",
    DestinyPlugSetDefinition: "DestinyPlugSetDefinition",
    DestinyChecklistDefinition: "DestinyChecklistDefinition",
    DestinyHistoricalStatsDefinition: "DestinyHistoricalStatsDefinition",
    DestinyMilestoneRewardEntryDefinition:
        "DestinyMilestoneRewardEntryDefinition",
    DestinyEnergyTypeDefinition: "DestinyEnergyTypeDefinition",
    DestinySeasonDefinition: "DestinySeasonDefinition",
    DestinySeasonPassDefinition: "DestinySeasonPassDefinition",
    DestinyPowerCapDefinition: "DestinyPowerCapDefinition",
    DestinyMetricDefinition: "DestinyMetricDefinition",
    DestinyTraitDefinition: "DestinyTraitDefinition"
  };
}
