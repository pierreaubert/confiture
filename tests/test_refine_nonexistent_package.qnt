module test_refine_nonexistent_package {
  import confiture.* from "../confiture"
  run test_refine_nonexistent_package = {
    init
    .then(refine_work_package(12345))
    .expect(not(work_results.keys().contains(12345)))
  }
}