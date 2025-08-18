module test_system_invariant_after_refine {
  import confiture.* from "../confiture"
  run test_system_invariant_after_refine = {
    init
    .then(deploy_service("alice", "inv_refine", MIN_SERVICE_BALANCE, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "p", gas_limit: 3,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "authInv"))
    .then(refine_work_package(0))
    .expect(system_invariant)
  }
}