# Architecture & Reuse Registry
> One line per durable thing. Edit the line when it changes; delete it when the thing is gone.
> No story narrative, no dates, no rationale.

## Shared utilities & components
| Export | Location | Capability |
| --- | --- | --- |
| `readScalarParam`, `readArrayParam`, `paginate`, `paginateByOffset` | `web/src/mocks/handler-utils.ts` | Query-param reading and page/offset slicing for MSW list handlers |

## Conventions
- MSW handlers compose entity factories from `web/src/mocks/data/` and `userInfoFor` for session/userinfo bodies.

## Cross-epic debt
