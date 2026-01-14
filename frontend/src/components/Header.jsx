import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useSettings, SPOILER_PREFS, THEMES } from '../context/SettingsContext'
import './Header.css'

function Header() {
  const [showSettings, setShowSettings] = useState(false)
  const { spoilerPref, setSpoilerPref, favorites, theme, toggleTheme } = useSettings()

  return (
    <header className="header">
      <div className="header-content">
        <div className="header-left">
          <Link to="/" className="logo">
            <span className="logo-icon">{'{ }'}</span>
            <span className="logo-text">AoC Algo Buddy</span>
          </Link>
          <p className="tagline">
            Master algorithms for Advent of Code
          </p>
        </div>
        <nav className="header-nav">
          <Link to="/submit" className="nav-link contribute-btn">
            + Contribute
          </Link>
          <button
            className="theme-toggle-btn"
            onClick={toggleTheme}
            title={theme === THEMES.DARK ? 'Switch to light theme' : 'Switch to dark theme'}
          >
            {theme === THEMES.DARK ? '\u2600' : '\u263D'}
          </button>
          <div className="settings-wrapper">
            <button
              className="settings-btn"
              onClick={() => setShowSettings(!showSettings)}
              title="Settings"
            >
              <span className="settings-icon">{'\u2699'}</span>
            </button>
            {showSettings && (
              <div className="settings-dropdown">
                <div className="settings-header">Settings</div>
                <div className="settings-section">
                  <label className="settings-label">AoC Spoilers</label>
                  <select
                    value={spoilerPref}
                    onChange={(e) => setSpoilerPref(e.target.value)}
                    className="settings-select"
                  >
                    <option value={SPOILER_PREFS.ASK}>Ask each time</option>
                    <option value={SPOILER_PREFS.SHOW}>Always show</option>
                    <option value={SPOILER_PREFS.HIDE}>Always hide</option>
                  </select>
                </div>
                <div className="settings-info">
                  {favorites.length} favorited algorithm{favorites.length !== 1 ? 's' : ''}
                </div>
              </div>
            )}
          </div>
        </nav>
      </div>
    </header>
  )
}

export default Header
