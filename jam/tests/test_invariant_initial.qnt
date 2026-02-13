module test_invariant_initial {
  import confiture.* from "../confiture"
  run test_invariant_initial = { init .expect(system_invariant) }
}