module test_refine_twice_no_duplicate_results {
  import confiture.* from "../confiture"
  run test_refine_twice_no_duplicate_results = {
    init
    .then(deploy_service("alice", "double_refine", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "p", gas_limit: 2,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "authR"))
    .then(refine_work_package(0))
    .then(refine_work_package(0))
    .expect(and {
      work_results.keys().size() == 1,
      work_results.keys().contains(0),
      not(pending_work_packages.exists(p => p.id == 0))
    })
  }
}