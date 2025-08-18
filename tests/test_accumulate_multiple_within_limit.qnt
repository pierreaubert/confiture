module test_accumulate_multiple_within_limit {
  import confiture.* from "../confiture"
  run test_accumulate_multiple_within_limit = {
    init
    .then(deploy_service("alice", "multi_acc", MIN_SERVICE_BALANCE + 200, "r","a","m"))
    .then(submit_work_package(0, Set({ id:0, service_id:0, payload:"p0", gas_limit:5, status:WorkPending, refine_output:"", accumulate_input:"" }), "m0"))
    .then(refine_work_package(0))
    .then(submit_work_package(0, Set({ id:1, service_id:0, payload:"p1", gas_limit:5, status:WorkPending, refine_output:"", accumulate_input:"" }), "m1"))
    .then(refine_work_package(1))
    .then(submit_work_package(0, Set({ id:2, service_id:0, payload:"p2", gas_limit:5, status:WorkPending, refine_output:"", accumulate_input:"" }), "m2"))
    .then(refine_work_package(2))
    .then(accumulate_work_results(Set(0,2)))
    .expect(jam_state_root == "state_accumulated")
  }
}