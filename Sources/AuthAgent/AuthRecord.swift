import GraniteAgents

/// The auth agent's place in Granite's roster: an app that links this package finds the `auth` agent by this record,
/// with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let authRecord: GraniteRoster.Record = { GraniteRoster.record(AuthAgent.self) }
