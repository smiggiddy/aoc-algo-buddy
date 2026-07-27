/// Slate <-> libghostty-vt C shim.
///
/// libghostty takes a `GhosttyAllocator` — a Zig `std.mem.Allocator` vtable
/// projected into C. Swift can't express those function pointers ergonomically
/// (and can't safely satisfy the alignment contract), so we provide a libc-backed
/// one here and hand Swift a pointer to it.
#ifndef SLATE_GHOSTTY_SHIM_H
#define SLATE_GHOSTTY_SHIM_H

#include <ghostty/vt.h>

#ifdef __cplusplus
extern "C" {
#endif

/// A process-wide, thread-safe allocator backed by posix_memalign/free.
///
/// The returned pointer has static storage duration — it is valid for the
/// lifetime of the process and must not be freed.
///
/// NOTE ON ALIGNMENT: the `alignment` parameter in the Zig allocator vtable is a
/// log2 exponent (`std.mem.Alignment`), not a byte count. If a future libghostty
/// revision changes that, this is the single place to fix it — and the symptom
/// will be immediate, loud heap corruption rather than anything subtle.
const GhosttyAllocator *slate_libc_allocator(void);

/// `GHOSTTY_INIT_SIZED` is a macro over a compound literal, which does not
/// import into Swift. These give Swift correctly-`size`-stamped structs.
GhosttyRenderStateColors slate_render_state_colors_init(void);
GhosttyStyle slate_style_init(void);
GhosttyRenderStateRowSelection slate_row_selection_init(void);

#ifdef __cplusplus
}
#endif

#endif /* SLATE_GHOSTTY_SHIM_H */
