module test_work_package_flow {
  import confiture.* from "../confiture"

  // Helper literal work item set
  val wi_set = Set({
    id: 0,
    service_id: 0,
    payload: "payload0",
    gas_limit: 5000,
    status: WorkPending,
    refine_output: "",
    accumulate_input: ""
  })

  // Test: Full flow submit -> refine -> accumulate
  run test_full_work_package_flow = {
    init
    .then(deploy_service("alice", "hash_code", 2000, "refine", "acc", "on_msg"))
    .then(submit_work_package(0, wi_set, "auth_sig"))
    .then(refine_work_package(0))
    .then(accumulate_work_results(Set(0)))
    .expect(and {
      state_core.work_results.keys().contains(0),
      state_core.work_results.get(0).success,
      state_core.work_packages.keys().contains(0),
      // After refinement + accumulation, state_chain.jam_state_root updated to "state_accumulated"
      state_chain.jam_state_root == "state_accumulated",
      state_core.cores.get(state_core.work_results.get(0).core_index).state == Available
    })
  }

  // Test: Cannot submit work package for inactive / missing service
  run test_submit_work_package_invalid_service = {
    init
    // No service deployed, should fail guard; state_core.pending_work_packages remains empty
    .then(submit_work_package(0, wi_set, "auth"))
    .expect(state_core.pending_work_packages.size() == 0)
  }

  // Test: Refine cannot run on non-existent package
  run test_refine_nonexistent_package = {
    init
    .then(refine_work_package(999))
    .expect(not(state_core.work_results.keys().contains(999)))
  }
}