import { createContext, useContext } from 'react'
import useLocalStorage from '../hooks/useLocalStorage'

const SettingsContext = createContext(null)

export const SPOILER_PREFS = {
  ASK: 'ask',
  SHOW: 'show',
  HIDE: 'hide'
}

export function SettingsProvider({ children }) {
  const [favorites, setFavorites] = useLocalStorage('aoc-favorites', [])
  const [spoilerPref, setSpoilerPref] = useLocalStorage('aoc-spoiler-pref', SPOILER_PREFS.ASK)

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

  const value = {
    favorites,
    toggleFavorite,
    isFavorite,
    spoilerPref,
    setSpoilerPref
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
