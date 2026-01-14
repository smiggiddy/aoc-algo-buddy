import { useEffect, useCallback } from 'react'

// Central shortcut definitions for help modal
export const SHORTCUTS = {
  NAVIGATION: [
    { key: 'j', description: 'Move down in list' },
    { key: 'k', description: 'Move up in list' },
    { key: 'Enter', description: 'Open focused algorithm' },
    { key: 'Escape', description: 'Clear focus / Close modal' },
  ],
  ACTIONS: [
    { key: '/', description: 'Focus search' },
    { key: 'f', description: 'Toggle favorite' },
    { key: '?', description: 'Show keyboard shortcuts' },
  ],
}

// Check if user is typing in an input field
const isTyping = () => {
  const activeEl = document.activeElement
  if (!activeEl) return false

  const tagName = activeEl.tagName.toLowerCase()
  const isInput = tagName === 'input' || tagName === 'textarea' || tagName === 'select'
  const isEditable = activeEl.isContentEditable

  return isInput || isEditable
}

/**
 * Hook for handling keyboard shortcuts
 * @param {Object} handlers - Object mapping keys to handler functions
 * @param {Object} options - Configuration options
 * @param {boolean} options.enableInInputs - Allow shortcuts while typing (default: false)
 * @param {boolean} options.enabled - Enable/disable shortcuts (default: true)
 */
export function useKeyboardShortcuts(handlers, options = {}) {
  const { enableInInputs = false, enabled = true } = options

  const handleKeyDown = useCallback((event) => {
    if (!enabled) return

    // Skip if user is typing (unless explicitly enabled)
    if (!enableInInputs && isTyping()) {
      // Exception: Escape should always work
      if (event.key !== 'Escape') return
    }

    // Build the key identifier
    let key = event.key

    // Handle special keys
    if (event.key === ' ') key = 'Space'

    // Check for modifier combinations
    const modifiers = []
    if (event.ctrlKey) modifiers.push('Ctrl')
    if (event.metaKey) modifiers.push('Meta')
    if (event.altKey) modifiers.push('Alt')
    if (event.shiftKey && key.length > 1) modifiers.push('Shift')

    const fullKey = [...modifiers, key].join('+')

    // Try full key first (e.g., "Ctrl+c"), then just the key
    const handler = handlers[fullKey] || handlers[key]

    if (handler) {
      event.preventDefault()
      handler(event)
    }
  }, [handlers, enabled, enableInInputs])

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [handleKeyDown])
}

/**
 * Hook specifically for list navigation with j/k keys
 * @param {number} itemCount - Total number of items
 * @param {Function} onSelect - Callback when item is selected (Enter)
 * @param {Object} options - Additional options
 */
export function useListNavigation(itemCount, onSelect, options = {}) {
  const {
    focusedIndex,
    setFocusedIndex,
    enabled = true,
    onEscape
  } = options

  const handlers = {
    'j': () => {
      if (itemCount === 0) return
      setFocusedIndex(prev =>
        prev === null ? 0 : Math.min(prev + 1, itemCount - 1)
      )
    },
    'k': () => {
      if (itemCount === 0) return
      setFocusedIndex(prev =>
        prev === null ? 0 : Math.max(prev - 1, 0)
      )
    },
    'Enter': () => {
      if (focusedIndex !== null && focusedIndex >= 0 && focusedIndex < itemCount) {
        onSelect(focusedIndex)
      }
    },
    'Escape': () => {
      setFocusedIndex(null)
      if (onEscape) onEscape()
    },
  }

  useKeyboardShortcuts(handlers, { enabled })

  return { focusedIndex, setFocusedIndex }
}

export default useKeyboardShortcuts
