// JAM Protocol Specification in Quint (0.7.2)                                   -*- quint -*-
//
// Join-Accumulate Machine: A trustless supercomputer combining Polkadot and Ethereum elements
// State of the specs is alpha

module confiture {

  type DataBlob = {
    id: int,
    data: str,
    size: int,
    erasure_coded: bool,
    availability_proof: str
  }

  type DataSegment = {
    blob_id: int,
    segment_index: int,
    data: str,
    proof: str
  }

  type ServiceState = ServiceInactive | ServiceActive | Suspended | Terminated

  type CoreState = Available | Occupied | Disputed
  type WorkItemStatus = WorkPending | InProgress | Refined | Accumulated | WorkFailed
  type WorkPackageStatus = WorkPackagePending | WorkPackageActive | WorkPackageCompleted | WorkPackageFailed

  // Core JAM Service definition with entry points (§2.2 Services)
  type Service = {
    id: int,
    owner: str,
    code_hash: str,
    state: ServiceState,
    balance: int,
    // Service entry points (§2.2.1 Service Entry Points)
    refine_code: str,      // fn refine() - in-core execution
    accumulate_code: str,  // fn accumulate() - on-chain execution
    on_message_code: str   // on_message() - inter-service messaging
  }

  // Work Package - collection of work items for a service (§3.1 Work Packages)
  type WorkPackage = {
    id: int,
    service_id: int,
    work_items: Set[WorkItem],
    authorization: str,
    context: WorkContext,
    status: WorkItemStatus,
    core_assignment: int,
    gas_limit: int,
    gas_consumed: int,
    accumulate_gas_limit: int,
    is_available: bool           // Enhanced availability check (§5.5)
  }

  // Core Region - represents a scheduled time on a core (§13)
  type CoreRegion = {
    core_index: int,
    service_id: int,
    start_block: int,
    end_block: int
  }

  type Reservation = {
    service_id: int,
    core_index: int
  }

  // Work Item - individual unit of work (§3.1.1 Work Items)
  type WorkItem = {
    id: int,
    service_id: int,
    payload: str,
    gas_limit: int,
    status: WorkItemStatus,
    refine_output: str,    // Output from refine phase (§3.2 Refinement)
    accumulate_input: str  // Input to accumulate phase (§3.3 Accumulation)
  }

  // Work Result - output from work package processing (§3.4 Work Results)
  type WorkResult = {
    package_id: int,
    service_id: int,
    core_index: int,
    refined_outputs: Set[str],
    accumulate_data: str,
    gas_used: int,
    accumulate_gas_used: int,
    success: bool
  }

  // Core - execution environment for work packages (§2.1 Cores)
  type Core = {
    index: int,
    state: CoreState,
    current_package: int,  // Work package ID being processed
    validator_set: Set[str], // Validators assigned to this core (§5.1 Validator Assignment)
    time_allocated: int
  }

  // Work Context - execution context for work packages (§3.1.2 Work Context)
  type WorkContext = {
    block_number: int,
    timestamp: int,
    entropy: str,           // Entropy from §4.3 Entropy Pool
    prior_state_root: str   // State root from previous block
  }

  // JAM Block Header - contains block metadata and commitments (§4.2 Block Header)
  type BlockHeader = {
    parent_hash: str,           // Hash of the parent block (§4.2.1)
    block_number: int,          // Sequential block number (§4.2.2)
    state_root: str,            // Root of the JAM state trie (§4.2.3)
    extrinsics_root: str,       // Root of extrinsics trie (§4.2.4)
    entropy_pool_root: str,     // Current entropy accumulator (§4.3)
    timestamp: int,             // Block timestamp (§4.2.5)
    epoch: int,                 // Current epoch number (§4.2.6)
    winning_tickets: Set[str],  // Winning lottery tickets for this block (§5.2)
    offenders_markers: Set[str], // Markers for validator offenses (§5.3)
    author_index: int,          // Index of the block author (§5.1)
    seal: str                   // Block seal/signature (§4.2.7)
  }

  // JAM Block - complete block structure (§4.2 Block Structure)
  type Block = {
    header: BlockHeader,                        // Block header (§4.2)
    extrinsics: Set[Extrinsic],                // Extrinsics (§4.4)
    guarantees: Set[Guarantee],                // Work guarantees (§5.4)
    assurances: Set[Assurance],                // Availability assurances (§5.5)
    preimages: Set[Preimage],                  // Data preimages (§4.5)
    availability: Set[AvailabilityAttestation] // Availability attestations (§5.6)
  }

  // Extrinsic - external transaction or operation (§4.4 Extrinsics)
  type Extrinsic = {
    id: int,
    extrinsic_type: ExtrinsicType,
    data: str,
    signature: str,
    author: str
  }

  type ExtrinsicType = Transfer | ServiceCallExtrinsic | WorkPackageSubmission | Governance

  // Guarantee - validator guarantee for work package execution (§5.4 Work Guarantees)
  type Guarantee = {
    work_package_hash: str,
    core_index: int,
    validator_index: int,
    signature: str,
    timeslot: int
  }

  // Assurance - assurance of work package availability (§5.5 Availability Assurances)
  type Assurance = {
    work_package_hash: str,
    assurer_index: int,
    signature: str,
    bitfield: str  // Availability bitfield
  }

  // Preimage - data preimage for work packages (§4.5 Data Preimages)
  type Preimage = {
    hash: str,
    data: str,
    length: int
  }

  // Availability Attestation - attestation of data availability (§5.6 Availability Attestations)
  type AvailabilityAttestation = {
    core_index: int,
    validator_index: int,
    availability_bitfield: str,
    signature: str
  }

  // Legacy service call for backward compatibility (§2.3 Service Calls)
  type ServiceCall = {
    caller: str,
    service_id: int,
    method: str,
    gas_limit: int,
    gas_price: int
  }

  // ============================================================================
  // SAFROLE CONSENSUS TYPES (§6 SAFROLE Consensus)
  // ============================================================================

  type ValidatorState = ValidatorActive | ValidatorInactive | Slashed
  type TicketStatus = TicketPending | Winning | Used | Expired

  // Validator entry in the validator set (§6.1 Validator Set)
  type Validator = {
    index: int,
    public_key: str,
    state: ValidatorState,
    stake: int,
    core_assignments: Set[int],     // Cores assigned to this validator
    last_block_authored: int
  }

  // SAFROLE ticket for block production (§6.2 Ticket System)
  type Ticket = {
    id: int,
    validator_index: int,
    slot_number: int,
    status: TicketStatus,
    signature: str
  }

  // Block seal containing SAFROLE proof (§6.3 Block Sealing)
  type SafroleSeal = {
    ticket_id: int,
    validator_signature: str,
    entropy_proof: str,
    slot_number: int
  }

  // ============================================================================
  // GRANDPA FINALITY TYPES (§7 GRANDPA Finality)
  // ============================================================================

  type VoteType = Prevote | Precommit
  type FinalityState = FinalityPending | Finalized | Conflicted

  // GRANDPA vote for finality (§7.1 GRANDPA Voting)
  type GrandpaVote = {
    voter_index: int,
    vote_type: VoteType,
    target_hash: str,
    target_number: int,
    signature: str,
    round_number: int
  }

  // GRANDPA justification for finalized blocks (§7.2 Finality Justification)
  type FinalityJustification = {
    round_number: int,
    target_hash: str,
    target_number: int,
    prevotes: Set[GrandpaVote],
    precommits: Set[GrandpaVote],
    finality_state: FinalityState
  }

  // ============================================================================
  // PVM (POLKA VIRTUAL MACHINE) TYPES (§8 PVM)
  // ============================================================================

  type PvmInstructionType = Load | Store | Compute | Branch | Call | Return
  type PvmExecutionState = Running | Paused | Completed | PvmFailed | AwaitingCall | OutOfGas

  // PVM program instruction (§8.1 PVM Instructions)
  type PvmInstruction = {
    opcode: PvmInstructionType,
    operands: List[int],           // RISC-V registers or immediates
    gas_cost: int
  }

  // PVM execution context (§8.2 PVM Execution Context)
  type PvmContext = {
    pc: int,                       // Program Counter (§8.2.1)
    registers: int -> int,         // Registers x0-x31 (§8.2.1)
    memory: int -> int,            // 64-bit Address Space (§8.2.2)
    gas_remaining: int,            // Gas (§8.2.3)
    execution_state: PvmExecutionState,
    return_data: str,
    service_id: int
  }

  // PVM program for service execution (§8.3 PVM Programs)
  type PvmProgram = {
    service_id: int,
    bytecode: str,
    instructions: int -> PvmInstruction, // PC -> Instruction
    gas_limit: int,
    memory_limit: int
  }

  // ============================================================================
  // CRYPTOGRAPHIC PRIMITIVES (§9 Cryptography)
  // ============================================================================

  type HashAlgorithm = Blake2b | Keccak256 | Sha256
  type SignatureScheme = Ed25519 | Sr25519 | Ecdsa

  // Cryptographic hash (§9.1 Hash Functions)
  type Hash = {
    algorithm: HashAlgorithm,
    input: str,
    output: str
  }

  // Digital signature (§9.2 Digital Signatures)
  type Signature = {
    scheme: SignatureScheme,
    public_key: str,
    message: str,
    signature: str,
    valid: bool
  }

  // Merkle tree for data integrity (§9.3 Merkle Trees)
  type MerkleTree = {
    root: str,
    leaves: Set[str],
    proofs: Set[str]
  }

  // ============================================================================
  // Dispute Resolution System types (§12 Disputes)
  // ============================================================================
  type DisputeType = InvalidWorkPackage | InvalidGuarantee | InvalidAssurance | SlashableOffense
  type DisputeStatus = DisputeOpen | DisputeResolved | DisputeRejected | DisputeSlashed

  type Dispute = {
    id: int,
    dispute_type: DisputeType,
    target_validator_index: int,
    evidence: str,
    status: DisputeStatus,
    initiated_by_index: int,
    block_number: int,
    resolution_votes: Set[int]    // Validator indices who voted
  }

  type SlashingEvent = {
    validator_index: int,
    amount: int,
    reason: DisputeType,
    block_number: int
  }

  // ============================================================================
  // Scheduling types (§13 Scheduling)
  // ============================================================================
  type WorkPackagePriority = High | Medium | Low
  type SchedulingPolicy = PriorityBased | GasWeighted | StakeWeighted | FIFO | DefaultScheduling

  type ScheduledWorkPackage = {
    package: WorkPackage,
    priority: WorkPackagePriority,
    submission_time: int,
    gas_fee: int,
    submitter_stake: int
  }

  // ============================================================================
  // CoreChains compatibility types (§14 CoreChains)
  // ============================================================================
  type ParachainState = Active | Inactive | Onboarding | Offboarding
  type XcmpMessageType = DownwardMessage | UpwardMessage | HorizontalMessage

  type Parachain = {
    id: int,
    genesis_head: str,
    validation_code: str,
    state: ParachainState,
    lease_period_start: int,
    lease_period_end: int
  }

  type XcmpMessage = {
    id: int,
    message_type: XcmpMessageType,
    source_para: int,
    dest_para: int,
    payload: str,
    processed: bool
  }

  type Message = {
    sender_id: int,
    recipient_id: int,
    payload: str,
    gas_limit: int
  }

  // ============================================================================
  // STATE VARIABLES (§1.3 JAM State)
  // ============================================================================

  // Basic state grouping for better organization
  type StateBasic = {
    current_block: int,
    services: int -> Service,                    // Service registry (§2.2)
    accounts: str -> int,                        // Account balances
    pending_calls: Set[ServiceCall],             // Pending service calls (§2.3)
    next_service_id: int,
    message_queue: List[Message]                 // Inter-service message queue
  }

  // Core execution state grouping (§2.1)
  type StateCore = {
    cores: int -> Core,
    work_packages: int -> WorkPackage,           // Work package registry (§3.1)
    work_results: int -> WorkResult,             // Work results (§3.4)
    pending_work_packages: Set[WorkPackage],
    next_package_id: int
  }

  // JAM Chain state grouping (§4.1)
  type StateChain = {
    next_work_item_id: int,
    jam_state_root: str,                         // JAM state root hash
    entropy_pool: str                            // Entropy accumulator (§6.3)
  }

  // Blockchain state grouping
  type StateBlockchain = {
    validator_assignments: int -> Set[int],      // Core to validator assignments
    blocks: int -> Block,                        // Block storage (§4.1)
    chain_head: int,                            // Current chain head block number
    current_epoch: int,                         // Current epoch number (§6.1)
    pending_extrinsics: Set[Extrinsic]          // Pending extrinsics (§5.1)
  }

  // SAFROLE consensus state grouping (§6 SAFROLE)
  type StateSafrole = {
    next_extrinsic_id: int,                     // Next available extrinsic ID
    validators: int -> Validator,               // Validator registry (§6.1)
    validator_count: int,                       // Current validator count
    tickets: Set[Ticket],                       // SAFROLE tickets (§6.2)
    pending_tickets: Set[Ticket],               // Pending ticket submissions
    current_slot: int                           // Current SAFROLE slot (§6.2)
  }

  // GRANDPA finality state grouping (§7 GRANDPA)
  type StateGrandpa = {
    entropy_accumulator: str,                   // SAFROLE entropy accumulator
    finalized_blocks: Set[int],                 // Finalized block numbers
    grandpa_round: int,                         // Current GRANDPA round
    pending_votes: Set[GrandpaVote]             // Pending GRANDPA votes
  }

  // PVM execution state grouping (§8 PVM)
  type StatePVM = {
    finality_justifications: int -> FinalityJustification, // GRANDPA justifications
    pvm_programs: int -> PvmProgram,            // Deployed PVM programs (by service_id)
    pvm_contexts: int -> PvmContext,            // Active PVM execution contexts
    pvm_gas_used: int,                          // Total PVM gas consumed
    next_context_id: int
  }

  // Data Availability state grouping (§11 Data Availability)
  type StateDataAvailability = {
    data_blobs: int -> DataBlob,                // Stored data blobs
    data_segments: int -> Set[DataSegment],     // Erasure coded segments
    next_blob_id: int,                          // Next available blob ID
    availability_threshold: int                 // Required availability threshold
  }

  // Dispute Resolution state grouping (§12 Disputes)
  type StateDispute = {
    disputes: int -> Dispute,
    next_dispute_id: int,
    slashing_events: Set[SlashingEvent]
  }

  // Advanced Scheduling state grouping (§13 Scheduling)
  type StateScheduling = {
    scheduled_packages: Set[ScheduledWorkPackage],
    scheduling_policy: SchedulingPolicy,
    core_regions: int -> CoreRegion              // Core assignments per timeslot
  }

  // CoreChains compatibility state grouping (§14 CoreChains)
  type StateCoreChains = {
    parachains: int -> Parachain,
    xcmp_messages: Set[XcmpMessage],
    next_xcmp_message_id: int
  }

  // Structured state variables for better organization
  var state_basic: StateBasic
  var state_core: StateCore
  var state_chain: StateChain
  var state_blockchain: StateBlockchain
  var state_safrole: StateSafrole
  var state_grandpa: StateGrandpa
  var state_pvm: StatePVM
  var state_data_availability: StateDataAvailability
  var state_dispute: StateDispute
  var state_scheduling: StateScheduling
  var state_corechains: StateCoreChains

  // ============================================================================
  // CONSTANTS
  // ============================================================================

  // Protocol constants (§1.2 Protocol Parameters)
  pure val MAX_GAS_PER_BLOCK = 15000000           // Maximum gas per block
  pure val REFINE_GAS_LIMIT = 100000              // Example limit for refine
  pure val ACCUMULATE_GAS_LIMIT = 1000            // Example limit for accumulate
  pure val MIN_SERVICE_BALANCE = 1000             // Minimum service balance (§2.2)
  pure val TOTAL_CORES = 341                      // JAM protocol specifies 341 cores (§2.1)
  pure val CORE_INDICES = 0.to(TOTAL_CORES - 1)
  pure val MAX_WORK_ITEMS_PER_PACKAGE = 16        // Maximum work items per package (§3.1)
  pure val VALIDATORS = Set(
       "val1", "val2", "val3",
       "val4", "val5", "val6"
  )                                               // Simplified validator set (§5.1)

  // SAFROLE constants (§6 SAFROLE Parameters)
  pure val SAFROLE_SLOT_DURATION = 6000           // 6 second slots (§6.2)
  pure val TICKETS_PER_EPOCH = 600                // Tickets issued per epoch (§6.2)
  pure val MIN_VALIDATOR_STAKE = 10000            // Minimum stake for validators (§6.1)
  pure val MAX_VALIDATORS = 1023                  // Maximum validator count (§6.1)
  pure val VALIDATOR_ROTATION_PERIOD = 100        // Epochs between validator rotations (§6.3)

  // GRANDPA constants (§7 GRANDPA Parameters)
  pure val GRANDPA_ROUND_DURATION = 30            // seconds per GRANDPA round (§7.3)
  pure val GRANDPA_THRESHOLD = 5                  // minimum votes needed for finalization (§7.2)
  pure val FINALITY_THRESHOLD = 2                 // 2/3 supermajority (§7.2)

  // PVM constants (§8 PVM Parameters)
  pure val PVM_MAX_MEMORY = 1048576               // 1MB max memory per program (§8.2)
  pure val PVM_MAX_STACK_SIZE = 1024              // Max stack depth (§8.2)
  pure val PVM_GAS_PER_INSTRUCTION = 1            // Base gas cost per instruction (§8.4)

  // Economic constants (§10 Economics)
  pure val BLOCK_REWARD = 1000                    // Reward for block production (§10.2)

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================

  // Calculate total cost for a caller across a set of calls (§2.3 Service Call Economics)
  pure def total_cost_for_caller(calls: Set[ServiceCall], caller: str): int =
    calls.filter(call => call.caller == caller)
         .fold(0, (acc, call) => acc + call.gas_limit * call.gas_price)

  // Check if a set of calls can be afforded by all callers (§2.3 Service Call Economics)
  pure def calls_affordable(calls: Set[ServiceCall], account_balances: str -> int): bool =
    account_balances.keys().forall(caller =>
      account_balances.get(caller) >= total_cost_for_caller(calls, caller)
    )

  // JAM-specific helper functions

  // Calculate total gas for work items in a package (§3.1 Work Package Gas)
  pure def package_gas_total(items: Set[WorkItem]): int =
    items.fold(0, (acc, work_item) => acc + work_item.gas_limit)

  // Check if a core is available for assignment (§2.1 Core Availability)
  pure def core_available(core: Core): bool =
    core.state == Available

  // Get available cores (§2.1 Core Management)
  pure def available_cores(core_map: int -> Core): Set[int] =
    CORE_INDICES.filter(i => core_available(core_map.get(i)))

  // Create work context for current block (§3.1.2 Work Context Creation)
  pure def create_work_context(block_num: int, entropy: str, state_root: str, timestamp: int): WorkContext =
  {
    block_number: block_num,
    timestamp: timestamp,
    entropy: entropy,
    prior_state_root: state_root
  }

  // ============================================================================
  // Create genesis block (§4.2 Genesis Block)
  // ============================================================================
  pure def create_genesis_block(): Block = {
    val genesis_header = {
      parent_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      block_number: 0,
      state_root: "genesis_state",
      extrinsics_root: "empty_extrinsics",
      entropy_pool_root: "initial_entropy",
      timestamp: 0,
      epoch: 0,
      winning_tickets: Set(),
      offenders_markers: Set(),
      author_index: 0,
      seal: "genesis_seal"
    }
    {
      header: genesis_header,
      extrinsics: Set(),
      guarantees: Set(),
      assurances: Set(),
      preimages: Set(),
      availability: Set()
    }
  }

  // ============================================================================
  // Create block header for new block (§4.2 Block Header Construction)
  // ============================================================================
  pure def create_block_header(parent_hash: str, block_num: int, state_root: str, entropy_root: str, timestamp: int, epoch: int): BlockHeader = {
    parent_hash: parent_hash,
    block_number: block_num,
    state_root: state_root,
    extrinsics_root: "extrinsics_root",
    entropy_pool_root: entropy_root,
    timestamp: timestamp,
    epoch: epoch,
    winning_tickets: Set(),
    offenders_markers: Set(),
    author_index: 0,
    seal: "block_seal"
  }

  // ============================================================================
  // INVARIANTS
  // ============================================================================

  // Account balances should be non-negative
  val accounts_non_negative =
    state_basic.accounts.keys().forall(acc => state_basic.accounts.get(acc) >= 0)

  // Service balances should be non-negative
  val service_balances_non_negative =
    state_basic.services.keys().forall(id => state_basic.services.get(id).balance >= 0)

  // Active services should have minimum balance
  val active_services_funded =
    state_basic.services.keys().forall(id => {
      val service = state_basic.services.get(id)
      service.state != ServiceActive or service.balance >= MIN_SERVICE_BALANCE
    })

  // Block numbers should be monotonic
  val blocks_monotonic = state_basic.current_block >= 0

  // Conservation of funds - total money in system should remain constant
  val total_funds =
    state_basic.accounts.keys().fold(0, (sum, acc) => sum + state_basic.accounts.get(acc)) +
    state_basic.services.keys().fold(0, (sum, id) => sum + state_basic.services.get(id).balance) +
    state_safrole.validators.keys().fold(0, (sum, id) => sum + state_safrole.validators.get(id).stake)

  val funds_conservation = total_funds == 35000  // Initial total: 10000 + 10000 + 5000 + 10000

  // Total system invariant
  val system_invariant = and {
    accounts_non_negative,
    service_balances_non_negative,
    active_services_funded,
    blocks_monotonic,
    funds_conservation
  }

  // ============================================================================
  // Actions
  // ============================================================================
  action deploy_service(
  	 owner: str,
	 code_hash: str,
	 initial_balance: int,
	 refine_code: str,
	 accumulate_code: str,
	 on_message_code: str
    ): bool = {
    val can_deploy = and {
      state_basic.accounts.keys().contains(owner),
      state_basic.accounts.get(owner) >= initial_balance,
      initial_balance >= MIN_SERVICE_BALANCE
    }
    val new_service = {
      id: state_basic.next_service_id,
      owner: owner,
      code_hash: code_hash,
      state: ServiceActive,
      balance: initial_balance,
      refine_code: refine_code,
      accumulate_code: accumulate_code,
      on_message_code: on_message_code
    }

    all {
      can_deploy,
      // Canonical effect set with actual updates
      state_basic' = {
        ...state_basic,
        services: state_basic.services.put(state_basic.next_service_id, new_service),
        accounts: state_basic.accounts.setBy(owner, balance => balance - initial_balance),
        next_service_id: state_basic.next_service_id + 1
      },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Send a message between services (§2.2.1)
  action send_message(sender_id: int, recipient_id: int, payload: str, gas_limit: int): bool = {
    val sender_exists = state_basic.services.keys().contains(sender_id)
    val recipient_exists = state_basic.services.keys().contains(recipient_id)
    val can_send = and {
      sender_exists,
      recipient_exists,
      state_basic.services.get(sender_id).balance >= gas_limit
    }
    val new_message = {
      sender_id: sender_id,
      recipient_id: recipient_id,
      payload: payload,
      gas_limit: gas_limit
    }
    all {
      can_send,
      state_basic' = {
        ...state_basic,
        services: state_basic.services.setBy(sender_id, s => { ...s, balance: s.balance - gas_limit }),
        message_queue: state_basic.message_queue.append(new_message)
      },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Submit a work package for processing
  action submit_work_package(service_id: int, work_items: Set[WorkItem], authorization: str): bool = {
    val service_exists = state_basic.services.keys().contains(service_id)
    val service = if (service_exists) state_basic.services.get(service_id) else {
      id: 0, owner: "", code_hash: "", state: ServiceInactive, balance: 0,
      refine_code: "", accumulate_code: "", on_message_code: ""
    }
    val total_gas = package_gas_total(work_items)
    val available_core_set = available_cores(state_core.cores)
    val can_submit = and {
      service_exists,
      service.state == ServiceActive,
      work_items.size() <= MAX_WORK_ITEMS_PER_PACKAGE,
      work_items.size() > 0,
      total_gas <= MAX_GAS_PER_BLOCK,
      available_core_set.size() > 0
    }
    val selected_core = if (can_submit and available_core_set.size() > 0) available_core_set.fold(0, (acc, core) => core) else 0
    nondet rand_ts = 1.to(100).oneOf()
    val timestamp = service_id * SAFROLE_SLOT_DURATION + rand_ts
    nondet rand_gaz_limit = 1000.to(10000).oneOf()
    nondet rand_gaz_consumed = 100.to(200).oneOf()
    val new_package = {
      id: state_core.next_package_id,
      service_id: service_id,
      work_items: work_items,
      authorization: authorization,
      context: create_work_context(service_id, authorization, "context_data", timestamp),
      status: WorkPending,
      core_assignment: selected_core,
      gas_limit: rand_gaz_limit,
      gas_consumed: rand_gaz_consumed,
      accumulate_gas_limit: ACCUMULATE_GAS_LIMIT,
      is_available: false
    }

    all {
      can_submit,
      state_basic' = state_basic,
      state_core' = {
        ...state_core,
        cores: state_core.cores.setBy(selected_core, core => { ...core, state: Occupied, current_package: state_core.next_package_id }),
        pending_work_packages: state_core.pending_work_packages.union(Set(new_package)),
        next_package_id: state_core.next_package_id + 1
      },
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Confirm availability of a work package (§5.5)
  action confirm_availability(package_id: int): bool = {
    val package_exists = state_core.work_packages.keys().contains(package_id)
    val wp = if (package_exists) state_core.work_packages.get(package_id) else {
      id: 0, service_id: 0, work_items: Set(), authorization: "", context: create_work_context(0, "", "", 0), status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0, accumulate_gas_limit: 0, is_available: false
    }
    // Simulate 2/3 supermajority verification
    val has_supermajority = true 
    all {
      package_exists,
      not(wp.is_available),
      has_supermajority,
      state_basic' = state_basic,
      state_core' = {
        ...state_core,
        work_packages: state_core.work_packages.setBy(package_id, p => { ...p, is_available: true })
      },
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Refine phase - execute work items in-core
  action refine_work_package(package_id: int): bool = {
    val package_exists = state_core.pending_work_packages.exists(pkg => pkg.id == package_id)
    val work_package = if (package_exists)
      state_core.pending_work_packages.filter(pkg => pkg.id == package_id).fold({
        id: 0,
	service_id: 0,
	work_items: Set(),
	authorization: "",
	context: {
	  block_number: 0,
	  timestamp: 0,
	  entropy: "",
	  prior_state_root: ""
	},
	status: WorkPending,
	core_assignment: 0,
	gas_limit: 0,
	gas_consumed: 0,
	accumulate_gas_limit: 0,
	is_available: false
      }, (acc, pkg) => pkg)
      else {
        id: 0,
	service_id: 0,
	work_items: Set(),
	authorization: "",
	context: create_work_context(0, "", "", 0),
	status: WorkPending,
	core_assignment: 0,
	gas_limit: 0,
	gas_consumed: 0,
	accumulate_gas_limit: 0,
	is_available: false
      }
    val service_exists = state_basic.services.keys().contains(work_package.service_id)
    val service = if (service_exists) state_basic.services.get(work_package.service_id) else {
      id: 0,
      owner: "",
      code_hash: "",
      state: ServiceInactive,
      balance: 0,
      refine_code: "",
      accumulate_code: "",
      on_message_code: ""
    }
    val can_refine = and {
      package_exists,
      service_exists,
      service.state == ServiceActive,
      state_core.cores.get(work_package.core_assignment).state == Occupied
    }
    // Simulate refine execution initialization (§3.2)
    val refined_items = work_package.work_items.map(wi =>
      { ...wi, status: InProgress }
    )
    val refined_package = { ...work_package, work_items: refined_items }
    
    // Create a PVM context for each work item (simplified: one per package)
    val new_ctx_id = state_pvm.next_context_id
    val new_ctx = {
      pc: 0,
      registers: 0.to(31).mapBy(_ => 0),
      memory: Map(),
      gas_remaining: work_package.gas_limit,
      execution_state: Running,
      return_data: "",
      service_id: work_package.service_id
    }

    all {
      can_refine,
      state_basic' = state_basic,
      state_core' = {
        ...state_core,
        work_packages: state_core.work_packages.put(package_id, refined_package),
        pending_work_packages: state_core.pending_work_packages.exclude(Set(work_package)),
        // In this refined model, we don't complete refinement immediately
        cores: state_core.cores.setBy(work_package.core_assignment, core => { ...core, current_package: package_id })
      },
      state_pvm' = {
        ...state_pvm,
        pvm_contexts: state_pvm.pvm_contexts.put(new_ctx_id, new_ctx),
        next_context_id: new_ctx_id + 1
      },
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Complete refinement after PVM execution is finished
  action complete_refinement(package_id: int, context_id: int): bool = {
    val package_exists = state_core.work_packages.keys().contains(package_id)
    val pkg = if (package_exists) state_core.work_packages.get(package_id) else {
      id: 0, service_id: 0, work_items: Set(), authorization: "", context: create_work_context(0, "", "", 0), status: WorkPending, core_assignment: 0, gas_limit: 0, gas_consumed: 0, accumulate_gas_limit: 0, is_available: false
    }
    val context_exists = state_pvm.pvm_contexts.keys().contains(context_id)
    val ctx = if (context_exists) state_pvm.pvm_contexts.get(context_id) else {
      pc: 0, registers: Map(), memory: Map(), gas_remaining: 0, execution_state: PvmFailed, return_data: "", service_id: 0
    }
    
    val can_complete = and {
      package_exists,
      context_exists,
      ctx.execution_state == Completed,
      ctx.service_id == pkg.service_id
    }

    val refined_items = pkg.work_items.map(wi =>
      { ...wi, status: Refined, refine_output: ctx.return_data }
    )
    val refined_package = { ...pkg, work_items: refined_items }
    val work_result = {
      package_id: package_id,
      service_id: pkg.service_id,
      core_index: pkg.core_assignment,
      refined_outputs: refined_items.map(work_item => work_item.refine_output),
      accumulate_data: "accumulate_input",
      gas_used: pkg.gas_limit - ctx.gas_remaining,
      accumulate_gas_used: pkg.accumulate_gas_limit / 2,
      success: true
    }

    all {
      can_complete,
      state_basic' = state_basic,
      state_core' = {
        ...state_core,
        work_packages: state_core.work_packages.put(package_id, refined_package),
        work_results: state_core.work_results.put(package_id, work_result),
        cores: state_core.cores.setBy(pkg.core_assignment, core => { ...core, state: Available, current_package: 0 })
      },
      state_pvm' = {
        ...state_pvm,
        pvm_contexts: state_pvm.pvm_contexts.keys().exclude(Set(context_id)).mapBy(k => state_pvm.pvm_contexts.get(k))
      },
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Accumulate phase - process refined results on-chain
  action accumulate_work_results(result_ids: Set[int]): bool = {
    val results_exist = result_ids.forall(id => state_core.work_results.keys().contains(id))
    val all_available = result_ids.forall(id => 
      val result = state_core.work_results.get(id)
      state_core.work_packages.get(result.package_id).is_available
    )
    val can_accumulate = and {
      results_exist,
      all_available,
      result_ids.size() > 0,
      result_ids.size() <= 10  // Limit accumulation batch size
    }
    val results_to_process = result_ids.map(id => state_core.work_results.get(id))
    val total_gas_used = results_to_process.fold(0, (acc, result) => acc + result.gas_used)
    // Simulate accumulate execution - in real implementation this would execute service.accumulate_code
    val new_state_root = "state_accumulated"
    all {
      can_accumulate,
      state_basic' = state_basic,
      state_core' = {
        ...state_core,
        work_packages: result_ids.fold(state_core.work_packages, (packages, result_id) => {
          val result = state_core.work_results.get(result_id)
          val package = packages.get(result.package_id)
          val accumulated_items = package.work_items.map(wi =>
            if (wi.status == Refined) { ...wi, status: Accumulated } else wi
          )
          packages.put(result.package_id, { ...package, work_items: accumulated_items })
        })
      },
      state_chain' = { ...state_chain, jam_state_root: new_state_root },
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Legacy service call for backward compatibility
  action submit_service_call(caller: str, service_id: int, method: str, gas_limit: int, gas_price: int): bool = {
    val can_call = and {
      state_basic.accounts.keys().contains(caller),
      state_basic.services.keys().contains(service_id),
      state_basic.services.get(service_id).state == ServiceActive,
      state_basic.accounts.get(caller) >= gas_limit * gas_price
    }
    val new_call = {
      caller: caller,
      service_id: service_id,
      method: method,
      gas_limit: gas_limit,
      gas_price: gas_price
    }

    all {
      can_call,
      state_basic' = {
        ...state_basic,
        pending_calls: state_basic.pending_calls.union(Set(new_call))
      },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Produce a new JAM block with work package processing
  action produce_block: bool = {
    val new_block_number = state_basic.current_block + 1
    val new_timestamp = new_block_number * SAFROLE_SLOT_DURATION

    // Process legacy service calls and convert to extrinsics
    val executable_calls = state_basic.pending_calls.filter(call =>
      calls_affordable(Set(call), state_basic.accounts)
    )
    val gas_limited_calls = executable_calls.filter(call => call.gas_limit <= MAX_GAS_PER_BLOCK)
    val total_gas = gas_limited_calls.fold(0, (acc, call) => acc + call.gas_limit)
    val final_calls = if (total_gas <= MAX_GAS_PER_BLOCK) gas_limited_calls else Set()

    // Convert service calls to extrinsics
    val service_call_extrinsics = final_calls.map(call => {
      id: state_safrole.next_extrinsic_id,
      extrinsic_type: ServiceCallExtrinsic,
      data: call.method,
      signature: "sig_caller",
      author: call.caller
    })

    // Process pending work packages (refine phase happens automatically)
    val packages_to_refine = state_core.pending_work_packages.filter(pkg =>
      state_core.cores.get(pkg.core_assignment).state == Occupied
    )

    // Update entropy and state root for new block
    val new_entropy = "entropy_updated"
    val new_state_root = "state_block_updated"
    val parent_hash = if (state_basic.current_block == 0) "genesis_hash" else "block_hash_prev"

    // Create new block header
    val new_header = create_block_header(parent_hash, new_block_number, new_state_root, new_entropy, new_timestamp, state_blockchain.current_epoch)

    // Generate guarantees from work package processing
    val work_guarantees = packages_to_refine.map(pkg => {
      work_package_hash: pkg.authorization,
      core_index: pkg.core_assignment,
      validator_index: if (state_safrole.validator_count > 0) pkg.core_assignment % state_safrole.validator_count else 0,
      signature: "guarantee_signature",
      timeslot: state_safrole.current_slot
    })

    // Generate assurances for work package availability
    val work_assurances = packages_to_refine.map(pkg => {
      work_package_hash: pkg.authorization,
      assurer_index: if (state_safrole.validator_count > 0) (pkg.core_assignment + 1) % state_safrole.validator_count else 0,
      signature: "assurance_signature",
      bitfield: "availability_bitfield"
    })

    // Generate preimages for work package data
    val work_preimages = packages_to_refine.map(pkg => {
      hash: pkg.authorization,
      data: pkg.authorization,
      length: 32  // Fixed length for simplicity
    })

    // Generate availability attestations from validators
    val availability_attestations = state_core.cores.keys().filter(core_id =>
      state_core.cores.get(core_id).state == Occupied
    ).map(core_id => {
      core_index: core_id,
      validator_index: if (state_safrole.validator_count > 0) core_id % state_safrole.validator_count else 0,  // Assign validator based on core
      availability_bitfield: "available_core",
      signature: "attestation_sig_core"
    })

    // Create new block
    val new_block = {
      header: new_header,
      extrinsics: service_call_extrinsics.union(state_blockchain.pending_extrinsics),
      guarantees: work_guarantees,
      assurances: work_assurances,
      preimages: work_preimages,
      availability: availability_attestations
    }

    all {
      state_basic' = {
        current_block: new_block_number,
        services: state_basic.services,
        accounts: final_calls.fold(state_basic.accounts, (acc_map, call) =>
          acc_map.setBy(call.caller, balance => balance - call.gas_limit * call.gas_price)
        ),
        pending_calls: state_basic.pending_calls.exclude(final_calls),
        next_service_id: state_basic.next_service_id,
        message_queue: state_basic.message_queue
      },
      state_core' = state_core,
      state_chain' = { ...state_chain, jam_state_root: new_state_root, entropy_pool: new_entropy },
      state_blockchain' = {
        ...state_blockchain,
        blocks: state_blockchain.blocks.put(new_block_number, new_block),
        chain_head: new_block_number,
        pending_extrinsics: Set()
      },
      state_safrole' = { ...state_safrole, next_extrinsic_id: state_safrole.next_extrinsic_id + service_call_extrinsics.size() },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // ============================================================================
  // INITIAL STATE (§1.3 JAM State Initialization)
  // ============================================================================

  action init = all {
    state_basic' = {
      current_block: 0,
      services: Map(),
      accounts: Map("alice" -> 10000, "bob" -> 10000, "charlie" -> 5000, "treasury" -> 10000),
      pending_calls: Set(),
      next_service_id: 1,
      message_queue: []
    },

    state_core' = {
      cores: CORE_INDICES.mapBy(i => {
        index: i,
        state: Available,
        current_package: 0,
        validator_set: Set(),
        time_allocated: 0
      }),
      work_packages: Map(),
      work_results: Map(),
      pending_work_packages: Set(),
      next_package_id: 1
    },

    state_chain' = {
      next_work_item_id: 1,
      jam_state_root: "genesis_state",
      entropy_pool: "initial_entropy"
    },

    state_blockchain' = {
      validator_assignments: CORE_INDICES.mapBy(_ => Set()),
      blocks: Map(0 -> {
        header: {
          parent_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          block_number: 0,
          state_root: "genesis_state",
          extrinsics_root: "empty_extrinsics",
          entropy_pool_root: "initial_entropy",
          timestamp: 0,
          epoch: 0,
          winning_tickets: Set(),
          offenders_markers: Set(),
          author_index: 0,
          seal: "genesis_seal"
        },
        extrinsics: Set(),
        guarantees: Set(),
        assurances: Set(),
        preimages: Set(),
        availability: Set()
      }),
      chain_head: 0,
      current_epoch: 0,
      pending_extrinsics: Set()
    },

    state_safrole' = {
      next_extrinsic_id: 1,
      validators: Map(),
      validator_count: 0,
      tickets: Set(),
      pending_tickets: Set(),
      current_slot: 0
    },

    state_grandpa' = {
      entropy_accumulator: "safrole_entropy",
      finalized_blocks: Set(0),  // Genesis block is finalized
      grandpa_round: 0,
      pending_votes: Set()
    },

    state_pvm' = {
      finality_justifications: Map(),
      pvm_programs: Map(),
      pvm_contexts: Map(),
      pvm_gas_used: 0,
      next_context_id: 1
    },

    state_data_availability' = {
      data_blobs: Map(),
      data_segments: Map(),
      next_blob_id: 1,
      availability_threshold: 2 * TOTAL_CORES / 3
    },

    state_dispute' = {
      disputes: Map(),
      next_dispute_id: 1,
      slashing_events: Set()
    },

    state_scheduling' = {
      scheduled_packages: Set(),
      scheduling_policy: DefaultScheduling,
      core_regions: Map()
    },

    state_corechains' = {
      parachains: Map(),
      xcmp_messages: Set(),
      next_xcmp_message_id: 1
    }
  }

  // Submit an extrinsic to the mempool
  action submit_extrinsic(extrinsic_type: ExtrinsicType, data: str, author: str): bool = {
    val can_submit = state_basic.accounts.keys().contains(author)
    val new_extrinsic = {
      id: state_safrole.next_extrinsic_id,
      extrinsic_type: extrinsic_type,
      data: data,
      signature: "sig_author",
      author: author
    }

    all {
      can_submit,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = { ...state_blockchain, pending_extrinsics: state_blockchain.pending_extrinsics.union(Set(new_extrinsic)) },
      state_safrole' = { ...state_safrole, next_extrinsic_id: state_safrole.next_extrinsic_id + 1 },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Reserve core-time for a service (§13)
  action reserve_core(service_id: int, core_idx: int): bool = {
    val service_exists = state_basic.services.keys().contains(service_id)
    val core_exists = CORE_INDICES.contains(core_idx)
    val already_reserved = state_scheduling.core_regions.keys().contains(core_idx)
    val can_reserve = and {
      service_exists,
      core_exists,
      not(already_reserved)
    }
    val new_region = {
      core_index: core_idx,
      service_id: service_id,
      start_block: state_basic.current_block,
      end_block: state_basic.current_block + 10
    }
    all {
      can_reserve,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = {
        ...state_scheduling,
        core_regions: state_scheduling.core_regions.put(core_idx, new_region)
      },
      state_corechains' = state_corechains
    }
  }

  // Terminate a service
  action terminate_service(service_id: int, caller: str): bool = {
    val service_exists = state_basic.services.keys().contains(service_id)
    val service = if (service_exists) state_basic.services.get(service_id) else {
      id: 0, owner: "", code_hash: "", state: ServiceInactive, balance: 0,
      refine_code: "", accumulate_code: "", on_message_code: ""
    }
    val can_terminate = and {
      service_exists,
      service.owner == caller,
      service.state == ServiceActive
    }
    all {
      can_terminate,
      state_basic' = {
        ...state_basic,
        services: state_basic.services.setBy(service_id, s => { ...s, state: Terminated, balance: 0 }),
        // Return service balance to the owner to maintain funds conservation
        accounts: state_basic.accounts.setBy(service.owner, balance => balance + service.balance)
      },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // ============================================================================
  // SAFROLE CONSENSUS ACTIONS (§6 SAFROLE)
  // ============================================================================

  // Register a new validator (§6.1 Validator Registration)
  action register_validator(public_key: str, stake: int): bool = {
    val can_register = and {
      stake >= MIN_VALIDATOR_STAKE,
      state_basic.accounts.keys().exists(account => state_basic.accounts.get(account) >= stake)
    }
    val updated_validator = {
      index: state_safrole.validator_count,
      public_key: public_key,
      state: ValidatorActive,
      stake: stake,
      core_assignments: Set(),
      last_block_authored: 0
    }
    all {
      can_register,
      nondet funding_account = state_basic.accounts.keys().filter(account => state_basic.accounts.get(account) >= stake).oneOf()
      state_basic' = { ...state_basic, accounts: state_basic.accounts.setBy(funding_account, balance => balance - stake) },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = { ...state_safrole,
        validators: state_safrole.validators.put(state_safrole.validator_count, updated_validator),
        validator_count: state_safrole.validator_count + 1
      },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Submit a SAFROLE ticket (§6.2 Ticket Submission)
  action submit_ticket(validator_index: int, slot_number: int): bool = {
    val can_submit = and {
      state_safrole.validators.keys().contains(validator_index),
      state_safrole.validators.get(validator_index).state == ValidatorActive,
      slot_number > state_safrole.current_slot
    }
    val ticket_id = validator_index * MAX_VALIDATORS + slot_number

    val new_ticket = {
      id: ticket_id,
      validator_index: validator_index,
      slot_number: slot_number,
      status: TicketPending,
      signature: "ticket_signature"
    }

    all {
      can_submit,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = { ...state_safrole, pending_tickets: state_safrole.pending_tickets.union(Set(new_ticket)) },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // ============================================================================
  // GRANDPA FINALITY ACTIONS (§7 GRANDPA)
  // ============================================================================

  // Submit a GRANDPA vote (§7.1 GRANDPA Voting)
  action submit_grandpa_vote(voter_index: int, vote_type: VoteType, target_hash: str, target_number: int): bool = {
    val can_vote = and {
      state_safrole.validators.keys().contains(voter_index),
      state_safrole.validators.get(voter_index).state == ValidatorActive,
      target_number <= state_blockchain.chain_head
    }
    val new_vote = {
      voter_index: voter_index,
      vote_type: vote_type,
      target_hash: target_hash,
      target_number: target_number,
      signature: "grandpa_signature",
      round_number: state_grandpa.grandpa_round
    }

    all {
      can_vote,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = { ...state_grandpa, pending_votes: state_grandpa.pending_votes.union(Set(new_vote)) },
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Finalize a block using GRANDPA (§7.2 GRANDPA Finalization)
  action finalize_block(target_hash: str, target_number: int): bool = {
    val current_round_votes = state_grandpa.pending_votes.filter(v => v.round_number == state_grandpa.grandpa_round)
    val prevotes = current_round_votes.filter(v => v.vote_type == Prevote and v.target_number == target_number)
    val precommits = current_round_votes.filter(v => v.vote_type == Precommit and v.target_number == target_number)

    val can_finalize = and {
      state_blockchain.blocks.keys().contains(target_number),
      state_blockchain.blocks.get(target_number).header.parent_hash == target_hash,
      prevotes.size() >= GRANDPA_THRESHOLD,
      precommits.size() >= GRANDPA_THRESHOLD,
      not(state_grandpa.finalized_blocks.contains(target_number))
    }

    val justification = {
      round_number: state_grandpa.grandpa_round,
      target_hash: target_hash,
      target_number: target_number,
      prevotes: prevotes,
      precommits: precommits,
      finality_state: Finalized
    }

    all {
      can_finalize,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = {
        ...state_grandpa,
        finalized_blocks: state_grandpa.finalized_blocks.union(Set(target_number)),
        grandpa_round: state_grandpa.grandpa_round + 1,
        pending_votes: Set()
      },
      state_pvm' = { ...state_pvm, finality_justifications: state_pvm.finality_justifications.put(target_number, justification) },
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Raise a dispute against a validator (§12.1)
  action raise_dispute(reporter_index: int, target_index: int, d_type: DisputeType): bool = {
    val reporter_exists = state_safrole.validators.keys().contains(reporter_index)
    val target_exists = state_safrole.validators.keys().contains(target_index)
    val can_raise = and {
      reporter_exists,
      target_exists,
      reporter_index != target_index,
      state_safrole.validators.get(reporter_index).state == ValidatorActive
    }
    val new_dispute = {
      id: state_dispute.next_dispute_id,
      dispute_type: d_type,
      target_validator_index: target_index,
      evidence: "evidence_data",
      status: DisputeOpen,
      initiated_by_index: reporter_index,
      block_number: state_basic.current_block,
      resolution_votes: Set(reporter_index)
    }
    all {
      can_raise,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = {
        ...state_dispute,
        disputes: state_dispute.disputes.put(state_dispute.next_dispute_id, new_dispute),
        next_dispute_id: state_dispute.next_dispute_id + 1
      },
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Vote on an open dispute (§12.2)
  action vote_on_dispute(voter_index: int, dispute_id: int): bool = {
    val voter_exists = state_safrole.validators.keys().contains(voter_index)
    val dispute_exists = state_dispute.disputes.keys().contains(dispute_id)
    val dispute = if (dispute_exists) state_dispute.disputes.get(dispute_id) else {
      id: 0, dispute_type: SlashableOffense, target_validator_index: 0, evidence: "", status: DisputeRejected, initiated_by_index: 0, block_number: 0, resolution_votes: Set()
    }
    val can_vote = and {
      voter_exists,
      dispute_exists,
      dispute.status == DisputeOpen,
      not(dispute.resolution_votes.contains(voter_index)),
      state_safrole.validators.get(voter_index).state == ValidatorActive
    }
    all {
      can_vote,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = {
        ...state_dispute,
        disputes: state_dispute.disputes.setBy(dispute_id, d => { ...d, resolution_votes: d.resolution_votes.union(Set(voter_index)) })
      },
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Resolve a dispute and apply slashing (§12.3)
  action resolve_dispute(dispute_id: int): bool = {
    val dispute_exists = state_dispute.disputes.keys().contains(dispute_id)
    val dispute = if (dispute_exists) state_dispute.disputes.get(dispute_id) else {
      id: 0, dispute_type: SlashableOffense, target_validator_index: 0, evidence: "", status: DisputeRejected, initiated_by_index: 0, block_number: 0, resolution_votes: Set()
    }
    // Simple supermajority check: > 1/2 of validators for this model
    val has_supermajority = dispute.resolution_votes.size() > state_safrole.validator_count / 2
    val can_resolve = and {
      dispute_exists,
      dispute.status == DisputeOpen,
      has_supermajority
    }
    
    val target_idx = dispute.target_validator_index
    val target_validator = state_safrole.validators.get(target_idx)
    val slash_amount = target_validator.stake / 2 // Slash 50% for this example
    
    val slashing_event = {
      validator_index: target_idx,
      amount: slash_amount,
      reason: dispute.dispute_type,
      block_number: state_basic.current_block
    }

    all {
      can_resolve,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = {
        ...state_safrole,
        validators: state_safrole.validators.setBy(target_idx, v => { ...v, stake: v.stake - slash_amount, state: Slashed })
      },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = {
        ...state_dispute,
        disputes: state_dispute.disputes.setBy(dispute_id, d => { ...d, status: DisputeResolved }),
        slashing_events: state_dispute.slashing_events.union(Set(slashing_event))
      },
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Force slash validator (§10.3 Validator Slashing)
  action force_slash_validator(validator_index: int): bool = {
    val can_slash = state_safrole.validators.keys().contains(validator_index)
    all {
      can_slash,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = { ...state_safrole, 
        validators: state_safrole.validators.setBy(validator_index, v => { ...v, state: Slashed, stake: 0 })
      },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Deploy a PVM program for a service (§8.3)
  action deploy_pvm_program(service_id: int, gas_limit: int): bool = {
    val service_exists = state_basic.services.keys().contains(service_id)
    val program = {
      service_id: service_id,
      bytecode: "riscv_binary_data",
      instructions: Map(
        0 -> { opcode: Compute, operands: [1, 2, 3], gas_cost: 10 },
        1 -> { opcode: Store, operands: [3, 100], gas_cost: 20 },
        2 -> { opcode: Return, operands: [3], gas_cost: 5 }
      ),
      gas_limit: gas_limit,
      memory_limit: PVM_MAX_MEMORY
    }
    all {
      service_exists,
      state_pvm' = {
        ...state_pvm,
        pvm_programs: state_pvm.pvm_programs.put(service_id, program)
      },
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Execute a single instruction in a PVM context (§8.4)
  action pvm_step(context_id: int): bool = {
    val context_exists = state_pvm.pvm_contexts.keys().contains(context_id)
    val ctx = if (context_exists) state_pvm.pvm_contexts.get(context_id) else {
      pc: 0, registers: Map(), memory: Map(), gas_remaining: 0, execution_state: PvmFailed, return_data: "", service_id: 0
    }
    val program_exists = state_pvm.pvm_programs.keys().contains(ctx.service_id)
    val program = state_pvm.pvm_programs.get(ctx.service_id)
    val instr_exists = program.instructions.keys().contains(ctx.pc)
    val instr = program.instructions.get(ctx.pc)
    
    val can_step = and {
      context_exists,
      program_exists,
      ctx.execution_state == Running,
      ctx.gas_remaining >= instr.gas_cost
    }

    val next_state = if (instr.opcode == Return) Completed else Running
    val next_ctx = {
      ...ctx,
      pc: if (next_state == Running) ctx.pc + 1 else ctx.pc,
      gas_remaining: ctx.gas_remaining - instr.gas_cost,
      execution_state: next_state
    }

    all {
      can_step,
      state_pvm' = {
        ...state_pvm,
        pvm_contexts: state_pvm.pvm_contexts.put(context_id, next_ctx),
        pvm_gas_used: state_pvm.pvm_gas_used + instr.gas_cost
      },
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // Distribute block rewards to validators (§10.2 Reward Distribution)
  action distribute_rewards(block_author_index: int, reward_amount: int): bool = {
    val can_distribute = and {
      state_safrole.validators.keys().contains(block_author_index),
      state_safrole.validators.get(block_author_index).state == ValidatorActive,
      reward_amount > 0,
      state_basic.accounts.get("treasury") >= reward_amount
    }
    all {
      can_distribute,
      state_basic' = {
        ...state_basic,
        accounts: state_basic.accounts.setBy("treasury", balance => balance - reward_amount)
      },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = { ...state_safrole,
        validators: state_safrole.validators.setBy(block_author_index, v => { ...v, stake: v.stake + reward_amount })
      },
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  // ============================================================================
  // SYSTEM STEP - Broken down for better type checking
  // ============================================================================

  action step_deploy_service = all {
    nondet caller = state_basic.accounts.keys().oneOf()
    deploy_service(caller, "code_hash", 1000, "refine_code", "accumulate_code", "on_message_code")
  }

  action step_submit_service_call = all {
    state_basic.services.keys().size() > 0,
    nondet caller = state_basic.accounts.keys().oneOf()
    nondet service_id = state_basic.services.keys().oneOf()
    nondet gas_limit = 1.to(100).oneOf()
    nondet gas_price = 1.to(10).oneOf()
    submit_service_call(caller, service_id, "call_data", gas_limit, gas_price)
  }

  action step_submit_work_package = all {
    state_basic.services.keys().size() > 0,
    nondet service_id = state_basic.services.keys().oneOf()
    nondet gas_limit = 10.to(100).oneOf()
    val work_item = {
      id: state_chain.next_work_item_id,
      service_id: service_id,
      payload: "payload",
      gas_limit: gas_limit,
      status: WorkPending,
      refine_output: "",
      accumulate_input: ""
    }
    val work_items = Set(work_item)
    submit_work_package(service_id, work_items, "auth_hash")
  }

  action step_register_validator = all {
    nondet caller = state_basic.accounts.keys().oneOf()
    register_validator("validator_key", MIN_VALIDATOR_STAKE)
  }

  action step_refine_work_package = all {
    state_core.work_packages.keys().size() > 0,
    nondet package_id = state_core.work_packages.keys().oneOf()
    refine_work_package(package_id)
  }

  action step_accumulate_work_results = {
    val available_results = state_core.work_results.keys().filter(id =>
      state_core.work_results.get(id).success == true
    )
    all {
      available_results.size() > 0,
      nondet result_id = available_results.oneOf()
      accumulate_work_results(Set(result_id))
    }
  }

  action step_reserve_core = all {
    state_basic.services.keys().size() > 0,
    nondet service_id = state_basic.services.keys().oneOf()
    nondet core_idx = CORE_INDICES.oneOf()
    reserve_core(service_id, core_idx)
  }

  action step_confirm_availability = all {
    state_core.work_packages.keys().size() > 0,
    nondet package_id = state_core.work_packages.keys().oneOf()
    confirm_availability(package_id)
  }

  action step_submit_extrinsic = all {
    nondet caller = state_basic.accounts.keys().oneOf()
    nondet extrinsic_type = Set(Transfer, ServiceCallExtrinsic, WorkPackageSubmission).oneOf()
    submit_extrinsic(extrinsic_type, "extrinsic_data", caller)
  }

  action step_terminate_service = all {
    state_basic.services.keys().size() > 0,
    nondet caller = state_basic.accounts.keys().oneOf()
    nondet service_id = state_basic.services.keys().oneOf()
    terminate_service(service_id, caller)
  }

  action step_submit_ticket = all {
    state_safrole.validators.keys().size() > 0,
    nondet validator_index = state_safrole.validators.keys().oneOf()
    nondet slot_number = Set(state_safrole.current_slot + 1, state_safrole.current_slot + 2).oneOf()
    submit_ticket(validator_index, slot_number)
  }

  action step_submit_grandpa_vote = all {
    state_safrole.validators.keys().size() > 0,
    nondet voter_index = state_safrole.validators.keys().oneOf()
    nondet vote_type = Set(Prevote, Precommit).oneOf()
    nondet target_number = Set(0, state_blockchain.chain_head).oneOf()
    submit_grandpa_vote(voter_index, vote_type, "block_hash", target_number)
  }

  action step_send_message = all {
    state_basic.services.keys().size() >= 2,
    nondet sender_id = state_basic.services.keys().oneOf()
    nondet recipient_id = state_basic.services.keys().filter(id => id != sender_id).oneOf()
    send_message(sender_id, recipient_id, "inter-service-payload", 100)
  }

  action process_messages: bool = {
    val can_process = state_basic.message_queue.length() > 0
    val msg = state_basic.message_queue.head()
    val remaining = state_basic.message_queue.tail()
    all {
      can_process,
      state_basic' = {
        ...state_basic,
        message_queue: remaining
        // In real implementation, this would trigger on_message code
      },
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = state_pvm,
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  action step_finalize_block = all {
    state_blockchain.blocks.keys().size() > 1,
    state_blockchain.chain_head > 0,
    not(state_grandpa.finalized_blocks.contains(state_blockchain.chain_head)),
    finalize_block("parent_hash", state_blockchain.chain_head)
  }

  action step_raise_dispute = all {
    state_safrole.validator_count >= 2,
    nondet reporter = state_safrole.validators.keys().oneOf()
    nondet target = state_safrole.validators.keys().filter(v => v != reporter).oneOf()
    nondet d_type = Set(InvalidWorkPackage, InvalidGuarantee, InvalidAssurance, SlashableOffense).oneOf()
    raise_dispute(reporter, target, d_type)
  }

  action step_vote_on_dispute = all {
    state_dispute.disputes.keys().size() > 0,
    nondet dispute_id = state_dispute.disputes.keys().oneOf()
    nondet voter = state_safrole.validators.keys().oneOf()
    vote_on_dispute(voter, dispute_id)
  }

  action step_resolve_dispute = all {
    state_dispute.disputes.keys().size() > 0,
    nondet dispute_id = state_dispute.disputes.keys().oneOf()
    resolve_dispute(dispute_id)
  }

  action step_distribute_rewards = all {
    state_safrole.validators.keys().size() > 0,
    nondet block_author = state_safrole.validators.keys().oneOf()
    nondet reward = Set(BLOCK_REWARD, BLOCK_REWARD / 2).oneOf()
    distribute_rewards(block_author, reward)
  }

  action step_deploy_pvm_program = all {
    state_basic.services.keys().size() > 0,
    nondet service_id = state_basic.services.keys().oneOf()
    deploy_pvm_program(service_id, 10000)
  }

  action step_pvm_step = all {
    state_pvm.pvm_contexts.keys().size() > 0,
    nondet ctx_id = state_pvm.pvm_contexts.keys().oneOf()
    pvm_step(ctx_id)
  }

  action step_complete_refinement = all {
    state_pvm.pvm_contexts.keys().size() > 0,
    nondet ctx_id = state_pvm.pvm_contexts.keys().oneOf()
    nondet pkg_id = state_core.work_packages.keys().oneOf()
    complete_refinement(pkg_id, ctx_id)
  }

  action step_consume_gas = any {
    all {
      state_pvm.pvm_gas_used + 100 <= MAX_GAS_PER_BLOCK,
      state_basic.accounts.get("treasury") >= 100,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = { ...state_pvm, pvm_gas_used: state_pvm.pvm_gas_used + 100 },
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    },
    all {
      state_pvm.pvm_gas_used + 500 <= MAX_GAS_PER_BLOCK,
      state_basic.accounts.get("treasury") >= 500,
      state_basic' = state_basic,
      state_core' = state_core,
      state_chain' = state_chain,
      state_blockchain' = state_blockchain,
      state_safrole' = state_safrole,
      state_grandpa' = state_grandpa,
      state_pvm' = { ...state_pvm, pvm_gas_used: state_pvm.pvm_gas_used + 500 },
      state_data_availability' = state_data_availability,
      state_dispute' = state_dispute,
      state_scheduling' = state_scheduling,
      state_corechains' = state_corechains
    }
  }

  action step_noop = all {
    state_basic' = state_basic,
    state_core' = state_core,
    state_chain' = state_chain,
    state_blockchain' = state_blockchain,
    state_safrole' = state_safrole,
    state_grandpa' = state_grandpa,
    state_pvm' = state_pvm,
    state_data_availability' = state_data_availability,
    state_dispute' = state_dispute,
    state_scheduling' = state_scheduling,
    state_corechains' = state_corechains
  }

  // Main step action - complete logic restored
  action step: bool = any {
    step_deploy_service,
    step_submit_service_call,
    step_submit_work_package,
    step_register_validator,
    step_reserve_core,
    step_refine_work_package,
    step_confirm_availability,
    step_accumulate_work_results,
    step_submit_extrinsic,
    produce_block,
    step_terminate_service,
    step_submit_ticket,
    step_submit_grandpa_vote,
    step_send_message,
    process_messages,
    step_finalize_block,
    step_raise_dispute,
    step_vote_on_dispute,
    step_resolve_dispute,
    step_distribute_rewards,
    step_deploy_pvm_program,
    step_pvm_step,
    step_complete_refinement,
    step_consume_gas,
    step_noop
  }

}

