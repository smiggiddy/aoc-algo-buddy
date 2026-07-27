#include "include/slate_ghostty_shim.h"

#include <stdlib.h>
#include <string.h>

/// Zig passes alignment as a log2 exponent. Clamp to something posix_memalign
/// will accept: it requires a power of two that is also a multiple of
/// sizeof(void *).
static size_t slate_alignment_bytes(uint8_t log2_alignment) {
    size_t alignment = (size_t)1 << log2_alignment;
    if (alignment < sizeof(void *)) alignment = sizeof(void *);
    return alignment;
}

static void *slate_alloc(void *ctx,
                         size_t len,
                         uint8_t alignment,
                         uintptr_t ret_addr) {
    (void)ctx;
    (void)ret_addr;
    if (len == 0) return NULL;

    void *ptr = NULL;
    if (posix_memalign(&ptr, slate_alignment_bytes(alignment), len) != 0) {
        return NULL;
    }
    return ptr;
}

static bool slate_resize(void *ctx,
                         void *memory,
                         size_t memory_len,
                         uint8_t alignment,
                         size_t new_len,
                         uintptr_t ret_addr) {
    (void)ctx;
    (void)memory;
    (void)alignment;
    (void)ret_addr;
    // We can honour shrink-in-place for free. Growing in place would require
    // knowing the true malloc bucket size, so we decline and let the caller
    // fall back to alloc + copy + free.
    return new_len <= memory_len;
}

static void *slate_remap(void *ctx,
                         void *memory,
                         size_t memory_len,
                         uint8_t alignment,
                         size_t new_len,
                         uintptr_t ret_addr) {
    (void)ctx;
    (void)memory;
    (void)memory_len;
    (void)alignment;
    (void)new_len;
    (void)ret_addr;
    // realloc() cannot preserve an over-aligned allocation, so remap is
    // unsupported. Returning NULL is a legal "couldn't do it" answer.
    return NULL;
}

static void slate_free(void *ctx,
                       void *memory,
                       size_t memory_len,
                       uint8_t alignment,
                       uintptr_t ret_addr) {
    (void)ctx;
    (void)memory_len;
    (void)alignment;
    (void)ret_addr;
    free(memory);
}

static const GhosttyAllocatorVtable slate_vtable = {
    .alloc = slate_alloc,
    .resize = slate_resize,
    .remap = slate_remap,
    .free = slate_free,
};

static const GhosttyAllocator slate_allocator = {
    .ctx = NULL,
    .vtable = &slate_vtable,
};

const GhosttyAllocator *slate_libc_allocator(void) {
    return &slate_allocator;
}

GhosttyRenderStateColors slate_render_state_colors_init(void) {
    return GHOSTTY_INIT_SIZED(GhosttyRenderStateColors);
}

GhosttyStyle slate_style_init(void) {
    GhosttyStyle style = GHOSTTY_INIT_SIZED(GhosttyStyle);
    ghostty_style_default(&style);
    // Re-stamp: the library is free to overwrite the whole struct, and every
    // sized struct must carry its own sizeof for forward compatibility.
    style.size = sizeof(GhosttyStyle);
    return style;
}

GhosttyRenderStateRowSelection slate_row_selection_init(void) {
    return GHOSTTY_INIT_SIZED(GhosttyRenderStateRowSelection);
}
