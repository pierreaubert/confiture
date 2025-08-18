module test_zero_gas_work_item {
  import confiture.* from "../confiture"
  run test_zero_gas_work_item = {
    init
    .then(deploy_service("alice", "zero_gas_svc", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "zero_gas", gas_limit: 0,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "zg"))
    .expect(pending_work_packages.size() == 1)
  }
}