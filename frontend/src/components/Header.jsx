import { Link } from 'react-router-dom'
import './Header.css'

function Header() {
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
        </nav>
      </div>
    </header>
  )
}

export default Header
