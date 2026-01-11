import { Link } from 'react-router-dom'
import './Header.css'

function Header() {
  return (
    <header className="header">
      <div className="header-content">
        <Link to="/" className="logo">
          <span className="logo-icon">{'{ }'}</span>
          <span className="logo-text">AoC Algo Buddy</span>
        </Link>
        <p className="tagline">
          Master algorithms for Advent of Code
        </p>
      </div>
    </header>
  )
}

export default Header
