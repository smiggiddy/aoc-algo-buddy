import { useState, useEffect } from 'react'
import './OfflineIndicator.css'

function OfflineIndicator() {
  const [isOnline, setIsOnline] = useState(navigator.onLine)
  const [showBanner, setShowBanner] = useState(false)

  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true)
      // Show "back online" message briefly
      setShowBanner(true)
      setTimeout(() => setShowBanner(false), 3000)
    }

    const handleOffline = () => {
      setIsOnline(false)
      setShowBanner(true)
    }

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  if (!showBanner) return null

  return (
    <div className={`offline-indicator ${isOnline ? 'online' : 'offline'}`}>
      {isOnline ? (
        <>
          <span className="indicator-icon">&#10003;</span>
          You're back online
        </>
      ) : (
        <>
          <span className="indicator-icon">&#9888;</span>
          You're offline. Some features may be limited.
        </>
      )}
    </div>
  )
}

export default OfflineIndicator
