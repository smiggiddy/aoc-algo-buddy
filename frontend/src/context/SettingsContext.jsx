import { createContext, useContext, useEffect } from 'react'
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

  // Apply theme to document root
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
  }, [theme])

  const toggleTheme = () => {
    setTheme(prev => prev === THEMES.DARK ? THEMES.LIGHT : THEMES.DARK)
  }

  const toggleFavorite = (algorithmId) => {
    setFavorites(prev => {
      if (prev.includes(algorithmId)) {
        return prev.filter(id => id !== algorithmId)
      }
      return [...prev, algorithmId]
    })
  }

  const isFavorite = (algorithmId) => {
    return favorites.includes(algorithmId)
  }

  const addRecentlyViewed = (algorithmId, algorithmName) => {
    setRecentlyViewed(prev => {
      // Remove if already exists
      const filtered = prev.filter(item => item.id !== algorithmId)
      // Add to front
      const newRecent = [{ id: algorithmId, name: algorithmName, viewedAt: Date.now() }, ...filtered]
      // Keep only the most recent
      return newRecent.slice(0, MAX_RECENT_ALGORITHMS)
    })
  }

  const value = {
    favorites,
    toggleFavorite,
    isFavorite,
    spoilerPref,
    setSpoilerPref,
    theme,
    toggleTheme,
    recentlyViewed,
    addRecentlyViewed
  }

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
