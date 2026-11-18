extends Resource
class_name VillageSpaces

@export var districts: Array[VillageSpace] = []


func space(id: String) -> VillageSpace:
	for district: VillageSpace in districts:
		if district.id == id:
			return district
	return null


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	var ids: Array[String] = []
	for district: VillageSpace in districts:
		if district == null or district.id in ids or district.id not in GardenIdentity.DISTRICTS:
			issues.append("Configura una sola geometría para cada barrio.")
			continue
		ids.append(district.id)
		issues.append_array(district.configuration_issues())
	if ids.size() != GardenIdentity.DISTRICTS.size():
		issues.append("Falta la geometría de un barrio.")
	return issues
