CONNECTIVITY PLAN
---
triggerDecision: skip
skipReason: No OpenAPI spec in documentation/; requirements.md (PI-01, PI-02) states all server behaviour is simulated client-side with in-memory fixtures. No backend to probe.

specStatus: missing
specPath: null

baseUrl:
  specServers: null
  envLocal: not-checked
  envExample: null
  divergence: none
  proposed: null

auth:
  schemeFromSpec: none
  schemeProposed: none
  headerProposed: null
  valueFormatProposed: null
  envVarsProposed: []
  envVarsPresentInLocal: none
  reachabilityOnly: false

smokeTest:
  endpoint: null
  rationale: No backend; nothing to probe.
  needsPathParams: false
  needsQueryParams: false

gapsForUser: []

corsRisk: false
corsNote: null

readyForSmokeTest: false
readyBlockers: [no spec, no backend (mock-only)]

curlFallbackRecommended: false
curlFallbackReason: null
