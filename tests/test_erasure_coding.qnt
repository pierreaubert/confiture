module test_erasure_coding {
  import confiture.* from "../confiture"

  // Test 5: Data blob erasure coding
  run test_erasure_coding = {
    init
    .then(store_data_blob("test_data", 100))
    .expect(and {
      data_segments.keys().contains(1),
      data_segments.get(1).size() == 4
    })
  }
}
