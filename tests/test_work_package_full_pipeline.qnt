module test_work_package_full_pipeline {
  import confiture.* from "../confiture"
  run test_work_package_full_pipeline = {
    init
    .then(deploy_service("alice", "full_wp", MIN_SERVICE_BALANCE + 100, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "payload0", gas_limit: 500,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "auth_sig"))
    .then(refine_work_package(0))
    .then(accumulate_work_results(Set(0)))
    .expect(and {
      work_results.keys().contains(0),
      work_results.get(0).success,
      jam_state_root == "state_accumulated"
    })
  }
}