import { Routes, Route } from 'react-router-dom'
import Header from './components/Header'
import AlgorithmList from './components/AlgorithmList'
import AlgorithmDetail from './components/AlgorithmDetail'
import SubmitForm from './components/SubmitForm'
import './App.css'

function App() {
  return (
    <div className="app">
      <Header />
      <main className="main">
        <Routes>
          <Route path="/" element={<AlgorithmList />} />
          <Route path="/algorithm/:id" element={<AlgorithmDetail />} />
          <Route path="/submit" element={<SubmitForm />} />
        </Routes>
      </main>
    </div>
  )
}

export default App
