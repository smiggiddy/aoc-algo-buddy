import { useState } from 'react'
import { Routes, Route } from 'react-router-dom'
import Header from './components/Header'
import AlgorithmList from './components/AlgorithmList'
import AlgorithmDetail from './components/AlgorithmDetail'
import SubmitForm from './components/SubmitForm'
import Dashboard from './pages/Dashboard'
import Compare from './pages/Compare'
import KeyboardHelpModal from './components/KeyboardHelpModal'
import { useKeyboardShortcuts } from './hooks/useKeyboardShortcuts'
import './App.css'

function App() {
  const [showKeyboardHelp, setShowKeyboardHelp] = useState(false)

  // Global keyboard shortcut for ? to show help
  useKeyboardShortcuts({
    '?': () => setShowKeyboardHelp(prev => !prev),
  })

  return (
    <div className="app">
      <Header />
      <main className="main">
        <Routes>
          <Route
            path="/"
            element={<AlgorithmList onShowHelp={() => setShowKeyboardHelp(true)} />}
          />
          <Route
            path="/algorithm/:id"
            element={<AlgorithmDetail onShowHelp={() => setShowKeyboardHelp(true)} />}
          />
          <Route path="/submit" element={<SubmitForm />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/compare" element={<Compare />} />
          <Route path="/compare/:ids" element={<Compare />} />
        </Routes>
      </main>
      {showKeyboardHelp && (
        <KeyboardHelpModal onClose={() => setShowKeyboardHelp(false)} />
      )}
    </div>
  )
}

export default App
