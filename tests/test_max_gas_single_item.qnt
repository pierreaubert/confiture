module test_max_gas_single_item {
  import confiture.* from "../confiture"
  run test_max_gas_single_item = {
    init
    .then(deploy_service("alice", "max_gas_svc", MIN_SERVICE_BALANCE + 1, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "max_gas",
      gas_limit: MAX_GAS_PER_BLOCK, status: WorkPending, refine_output: "", accumulate_input: ""
    }), "mg"))
    .expect(pending_work_packages.size() == 1)
  }
}