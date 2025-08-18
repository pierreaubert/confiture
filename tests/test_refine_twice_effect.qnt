module test_refine_twice_effect {
  import confiture.* from "../confiture"
  run test_refine_twice_effect = {
    init
    .then(deploy_service("alice", "double_refine2", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "p", gas_limit: 2,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "authR"))
    .then(refine_work_package(0))
    .then(refine_work_package(0))
    .expect(work_results.keys().size() == 1)
  }
}