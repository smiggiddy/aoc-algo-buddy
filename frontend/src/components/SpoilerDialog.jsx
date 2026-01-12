import './SpoilerDialog.css'

function SpoilerDialog({ onConfirm, onCancel }) {
  return (
    <div className="spoiler-overlay" onClick={onCancel}>
      <div className="spoiler-dialog" onClick={e => e.stopPropagation()}>
        <div className="spoiler-icon">!</div>
        <h3 className="spoiler-title">Spoiler Warning</h3>
        <p className="spoiler-message">
          This section reveals which Advent of Code problems use this algorithm.
          Are you sure you want to see potential spoilers?
        </p>
        <div className="spoiler-actions">
          <button className="spoiler-btn spoiler-btn-cancel" onClick={onCancel}>
            No, keep hidden
          </button>
          <button className="spoiler-btn spoiler-btn-confirm" onClick={onConfirm}>
            Yes, show me
          </button>
        </div>
      </div>
    </div>
  )
}

export default SpoilerDialog
