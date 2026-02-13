module test_submit_when_core_occupied {
  import confiture.* from "../confiture"
  run test_submit_when_core_occupied = {
    init
    .then(deploy_service("alice", "core_busy_svc", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "p", gas_limit: 1,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "auth1"))
    .then(submit_work_package(0, Set({
      id: 1, service_id: 0, payload: "p2", gas_limit: 1,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "auth2"))
    .expect(state_core.pending_work_packages.size() == 1)
  }
}