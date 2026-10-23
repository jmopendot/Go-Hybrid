// ============================================================================
// 55-atomic-scalar-methods-accept — proposed corpus addition (ACCEPT side)
//
// PURPOSE: pin the METHOD SET of the scalar atomics, not just the type mapping.
// 48-safe-composite-move-control reaches only `store` on a struct field of type
// atomic.bool. Writing the same shape with the rest of Go's scalar API reaches
// rows the first fix missed: `compare_and_swap` was absent for every scalar
// atomic, INCLUDING the pre-existing `atomic.int64` row, so an accepted program
// calling `.compare_and_swap(...)` emitted `<field>.compare_and_swap` - a name Go
// does not have - and the module could not be built. `and` / `or` (Go 1.23+) were missing the same way,
// which is why this program exercises them too.
//
// The method set below is taken from the pinned toolchain's own source
// (sync/atomic/type.go, Go 1.26.9): Load / Store / Add / Swap / CompareAndSwap for
// the integer scalars, and Load / Store / Swap / CompareAndSwap for Bool (no Add).
// hy-check/src/foreign.rs documents the same list for its class-2 scalar atomics.
//
// ---- Expected verdict (pre-registered 2026-10-16, before running) ----
// EXPECTED-VERDICT: ACCEPT
//   ACCEPT — 0 annotations, 0 managed.
//
// ---- Reproduction ----
//   without the shape rows      : hyb check -> verdict=accept, 0 errors, but
//                                 `hyb build --emit-go && go build` fails on the
//                                 unmapped lowercase method name
//   with the rows added         : ACCEPT: exit 0 (verified through
//                                 tools/differential_loop.py on a corpus copy, on a pristine
//                                 clone of f0ccaa2 with only 0002 applied)
// ============================================================================

struct counters {
    flag atomic.bool
    n    atomic.uint64
    k    atomic.int64
}

fn worker(c counters, done chan<- bool) {
    _ = c.flag.load()
    c.flag.store(true)
    _ = c.flag.swap(false)
    _ = c.flag.compare_and_swap(true, false)
    _ = c.n.add(1)
    _ = c.n.compare_and_swap(1, 2)
    _ = c.k.add(-1)
    c.k.store(7)
    _ = c.k.swap(0)
    _ = c.k.compare_and_swap(1, 2)
    _ = c.n.and(3)          // Go 1.23+ integer API
    _ = c.n.or(4)
    _ = c.k.and(-1)
    _ = c.k.or(0)
    done <- true
}

fn main() {
    c := counters{}
    done := make(chan bool, 1)
    task worker(move c, done)
    <-done
}
