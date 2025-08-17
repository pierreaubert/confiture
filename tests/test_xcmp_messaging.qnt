module test_xcmp_messaging {
  import confiture.* from "../confiture"

  // Test 11: XCMP Message Passing
  run test_xcmp_messaging = {
    init
    .then(deploy_parachain(1000, "genesis_1", "code_1", 0, 100))
    .then(deploy_parachain(2000, "genesis_2", "code_2", 0, 100))
    .then(send_xcmp_message(1000, 2000, HorizontalMessage, "cross_chain_data"))
    .expect(and {
      xcmp_messages.size() == 1,
      next_xcmp_message_id == 2,
      xcmp_messages.exists(msg => msg.source_para == 1000 and msg.dest_para == 2000)
    })
  }
}
