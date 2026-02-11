# Implementation plan: Optional web search for uhow command

## Construction

- [x] update: [uspecs/u/actn-how.md](../../../../u/actn-how.md)
  - update: Line 8 - Change rule from "Web search is mandatory before asking questions" to "Web search is optional - performed only when Engineer specifies --web flag or mentions using web search, or when questions involve choosing between technologies/algorithms/patterns"
  - update: Lines 48-49 - Update Background to reflect conditional web search: "Given Questions are asked by 3" and "And Web search is performed when Engineer requests it or when questions involve technology/algorithm/pattern choices"

- [x] update: [uspecs/specs/prod/softeng/how.feature](../../../../../specs/prod/softeng/how.feature)
  - update: Lines 6-7 - Update Background to match actn-how.md: "Given Questions are asked by 3" and "And Web search is performed when Engineer requests it or when questions involve technology/algorithm/pattern choices"
