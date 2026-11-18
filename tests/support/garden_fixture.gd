extends RefCounted
class_name GardenFixture


static func complete_corner() -> GameSession:
	var session: GameSession = GameSession.new()
	for word: String in VocabularyCatalog.learnable_keys():
		session.learn_word(word)
	session.economy.awards = {"mayak": 4, "chich": 4}
	session.prepare_sharing_corner()
	session.magic_points = 1000
	session.purchase_combination_designs("mayak|chich")
	session.confirm_sharing_corner("mayak|chich")
	session.purchase_design("lak")
	session.scene_states.world5_cine1 = {"complete": true}
	session.rest_corner = {"intro": 3, "choice": "mayak", "complete": true, "result": 0}
	return session


static func complete_snack() -> GameSession:
	var session: GameSession = complete_corner()
	session.select_snack(["Kay", "Ch'íich'"], "K'úum|", "flowers")
	session.begin_snack_preparation()
	var activity: CountingActivity = CountingActivity.new()
	activity.setup(SnackState.counting_set(), session.snack_project.preparation)
	for round_index: int in range(2):
		activity.help()
		activity.help()
		activity.submit()
		activity.submit()
	session.update_snack_preparation(activity.snapshot())
	session.confirm_snack_project()
	return session
