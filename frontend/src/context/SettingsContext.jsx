import { createContext, useContext, useEffect, useCallback, useMemo } from 'react'
import useLocalStorage from '../hooks/useLocalStorage'

const SettingsContext = createContext(null)

export const SPOILER_PREFS = {
  ASK: 'ask',
  SHOW: 'show',
  HIDE: 'hide'
}

export const THEMES = {
  DARK: 'dark',
  LIGHT: 'light'
}

const MAX_RECENT_ALGORITHMS = 10

export function SettingsProvider({ children }) {
  const [favorites, setFavorites] = useLocalStorage('aoc-favorites', [])
  const [spoilerPref, setSpoilerPref] = useLocalStorage('aoc-spoiler-pref', SPOILER_PREFS.ASK)
  const [theme, setTheme] = useLocalStorage('aoc-theme', THEMES.DARK)
  const [recentlyViewed, setRecentlyViewed] = useLocalStorage('aoc-recently-viewed', [])
  const [learnedAlgorithms, setLearnedAlgorithms] = useLocalStorage('aoc-learned', [])
  const [algorithmNotes, setAlgorithmNotes] = useLocalStorage('aoc-notes', {})

  // Apply theme to document root
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
  }, [theme])

  const toggleTheme = useCallback(() => {
    setTheme(prev => prev === THEMES.DARK ? THEMES.LIGHT : THEMES.DARK)
  }, [setTheme])

  const toggleFavorite = useCallback((algorithmId) => {
    setFavorites(prev => {
      if (prev.includes(algorithmId)) {
        return prev.filter(id => id !== algorithmId)
      }
      return [...prev, algorithmId]
    })
  }, [setFavorites])

  const isFavorite = useCallback((algorithmId) => {
    return favorites.includes(algorithmId)
  }, [favorites])

  const addRecentlyViewed = useCallback((algorithmId, algorithmName) => {
    setRecentlyViewed(prev => {
      // Remove if already exists
      const filtered = prev.filter(item => item.id !== algorithmId)
      // Add to front
      const newRecent = [{ id: algorithmId, name: algorithmName, viewedAt: Date.now() }, ...filtered]
      // Keep only the most recent
      return newRecent.slice(0, MAX_RECENT_ALGORITHMS)
    })
  }, [setRecentlyViewed])

  const toggleLearned = useCallback((algorithmId) => {
    setLearnedAlgorithms(prev => {
      const existing = prev.find(item => item.id === algorithmId)
      if (existing) {
        return prev.filter(item => item.id !== algorithmId)
      }
      return [...prev, { id: algorithmId, learnedAt: new Date().toISOString() }]
    })
  }, [setLearnedAlgorithms])

  const isLearned = useCallback((algorithmId) => {
    return learnedAlgorithms.some(item => item.id === algorithmId)
  }, [learnedAlgorithms])

  const setNote = useCallback((algorithmId, note) => {
    setAlgorithmNotes(prev => {
      if (!note || note.trim() === '') {
        const { [algorithmId]: _, ...rest } = prev
        return rest
      }
      return { ...prev, [algorithmId]: note }
    })
  }, [setAlgorithmNotes])

  const getNote = useCallback((algorithmId) => {
    return algorithmNotes[algorithmId] || ''
  }, [algorithmNotes])

  const value = useMemo(() => ({
    favorites,
    toggleFavorite,
    isFavorite,
    spoilerPref,
    setSpoilerPref,
    theme,
    toggleTheme,
    recentlyViewed,
    addRecentlyViewed,
    learnedAlgorithms,
    toggleLearned,
    isLearned,
    algorithmNotes,
    setNote,
    getNote
  }), [
    favorites,
    toggleFavorite,
    isFavorite,
    spoilerPref,
    setSpoilerPref,
    theme,
    toggleTheme,
    recentlyViewed,
    addRecentlyViewed,
    learnedAlgorithms,
    toggleLearned,
    isLearned,
    algorithmNotes,
    setNote,
    getNote
  ])

  return (
    <SettingsContext.Provider value={value}>
      {children}
    </SettingsContext.Provider>
  )
}

export function useSettings() {
  const context = useContext(SettingsContext)
  if (!context) {
    throw new Error('useSettings must be used within a SettingsProvider')
  }
  return context
}
