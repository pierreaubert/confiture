module test_max_items_in_package {
  import confiture.* from "../confiture"
  
  // Helper for creating max work items
  val items = Set({
    id: 0, service_id: 0, payload: "pi0", gas_limit: 1,
    status: WorkPending, refine_output: "", accumulate_input: ""
  })
  
  run test_max_items_in_package = {
    init
    .then(deploy_service("alice", "max_items_svc", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_work_package(0, items, "authMaxItems"))
    .expect(state_core.pending_work_packages.size() == 1)
  }
}