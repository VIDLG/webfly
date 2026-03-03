/**
 * AI configuration storage — API key and model preferences.
 *
 * Uses SQLite via webf_sqflite when available, falls back to localStorage.
 */

import { query, execute, getDatabase } from './db.js'

const LS_PREFIX = 'ai_config:'

async function useSqlite(): Promise<boolean> {
  return (await getDatabase()) !== null
}

export async function getAIConfig(key: string): Promise<string | null> {
  if (await useSqlite()) {
    const rows = await query('SELECT value FROM ai_config WHERE key = ?', [key])
    return rows.length > 0 ? (rows[0].value as string) : null
  }
  return localStorage.getItem(`${LS_PREFIX}${key}`)
}

export async function setAIConfig(key: string, value: string): Promise<void> {
  if (await useSqlite()) {
    await execute(
      'INSERT OR REPLACE INTO ai_config (key, value) VALUES (?, ?)',
      [key, value],
    )
    return
  }
  localStorage.setItem(`${LS_PREFIX}${key}`, value)
}

export async function removeAIConfig(key: string): Promise<void> {
  if (await useSqlite()) {
    await execute('DELETE FROM ai_config WHERE key = ?', [key])
    return
  }
  localStorage.removeItem(`${LS_PREFIX}${key}`)
}

// Convenience accessors
export const getApiKey = () => getAIConfig('apiKey')
export const setApiKey = (key: string) => setAIConfig('apiKey', key)
export const getModel = () => getAIConfig('model')
export const setModel = (model: string) => setAIConfig('model', model)
