module test_negative_guards {
  import confiture.* from "../confiture"

  // Test: submit_service_call fails if service inactive (no deployment)
  run test_call_inactive_service = {
    init
    .then(submit_service_call("alice", 0, "methodZ", 10, 1))
    .expect(pending_calls.size() == 0)
  }

  // Helper for creating too many work items
  val big_set = CORE_INDICES // misuse: using many ints to exceed limit by crafting WorkItems
    .filter(i => i < (MAX_WORK_ITEMS_PER_PACKAGE + 2))
    .map(i => {
      id: i,
      service_id: 0,
      payload: "p",
      gas_limit: 1,
      status: WorkPending,
      refine_output: "",
      accumulate_input: ""
    })

  // Test: submit_work_package fails if exceeding MAX_WORK_ITEMS_PER_PACKAGE
  run test_submit_work_package_too_many_items = {
    init
    .then(deploy_service("alice", "h", 1500, "r", "a", "m"))
    .then(submit_work_package(0, big_set, "authX"))
    .expect(pending_work_packages.size() == 0)
  }
}