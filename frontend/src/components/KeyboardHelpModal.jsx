import { useEffect, useRef } from 'react'
import { SHORTCUTS } from '../hooks/useKeyboardShortcuts'
import './KeyboardHelpModal.css'

function KeyboardHelpModal({ onClose }) {
  const modalRef = useRef(null)

  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') {
        onClose()
      }
    }

    const handleClickOutside = (e) => {
      if (modalRef.current && !modalRef.current.contains(e.target)) {
        onClose()
      }
    }

    document.addEventListener('keydown', handleEscape)
    document.addEventListener('mousedown', handleClickOutside)

    // Prevent body scroll when modal is open
    document.body.style.overflow = 'hidden'

    return () => {
      document.removeEventListener('keydown', handleEscape)
      document.removeEventListener('mousedown', handleClickOutside)
      document.body.style.overflow = ''
    }
  }, [onClose])

  return (
    <div className="keyboard-help-overlay">
      <div className="keyboard-help-modal" ref={modalRef}>
        <div className="keyboard-help-header">
          <h2>Keyboard Shortcuts</h2>
          <button className="close-btn" onClick={onClose} title="Close (Escape)">
            &times;
          </button>
        </div>

        <div className="keyboard-help-content">
          <div className="shortcut-section">
            <h3>Navigation</h3>
            <ul className="shortcut-list">
              {SHORTCUTS.NAVIGATION.map(({ key, description }) => (
                <li key={key} className="shortcut-item">
                  <kbd className="shortcut-key">{key}</kbd>
                  <span className="shortcut-desc">{description}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="shortcut-section">
            <h3>Actions</h3>
            <ul className="shortcut-list">
              {SHORTCUTS.ACTIONS.map(({ key, description }) => (
                <li key={key} className="shortcut-item">
                  <kbd className="shortcut-key">{key}</kbd>
                  <span className="shortcut-desc">{description}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="shortcut-section">
            <h3>Code View</h3>
            <ul className="shortcut-list">
              <li className="shortcut-item">
                <kbd className="shortcut-key">Click line #</kbd>
                <span className="shortcut-desc">Select line</span>
              </li>
              <li className="shortcut-item">
                <kbd className="shortcut-key">Shift + Click</kbd>
                <span className="shortcut-desc">Select range</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="keyboard-help-footer">
          Press <kbd>?</kbd> to toggle this help
        </div>
      </div>
    </div>
  )
}

export default KeyboardHelpModal
