module test_work_package_submit_success {
  import confiture.* from "../confiture"
  run test_work_package_submit_success = {
    init
    .then(deploy_service("alice", "wp_hash", MIN_SERVICE_BALANCE + 100, "r","a","m"))
    .then(submit_work_package(0, Set({
      id: 0, service_id: 0, payload: "payload0", gas_limit: 500,
      status: WorkPending, refine_output: "", accumulate_input: ""
    }), "auth_sig"))
    .expect(pending_work_packages.size() == 1)
  }
}