/**
 * Effect overrides storage — saves AI-modified effect code and UI specs.
 *
 * Uses SQLite via webf_sqflite when available, falls back to localStorage.
 */

import { query, execute, getDatabase } from './db.js'

export interface EffectOverride {
  uiJson: string
  effectCode: string
  bridgeConfig?: string
}

const LS_PREFIX = 'effect_override:'

async function useSqlite(): Promise<boolean> {
  return (await getDatabase()) !== null
}

export async function saveEffectOverride(
  effectId: string,
  data: EffectOverride,
): Promise<void> {
  if (await useSqlite()) {
    await execute(
      `INSERT OR REPLACE INTO effect_overrides (effect_id, ui_json, effect_code, bridge_config, updated_at)
       VALUES (?, ?, ?, ?, datetime('now'))`,
      [effectId, data.uiJson, data.effectCode, data.bridgeConfig ?? null],
    )
    return
  }
  localStorage.setItem(`${LS_PREFIX}${effectId}`, JSON.stringify(data))
}

export async function loadEffectOverride(
  effectId: string,
): Promise<EffectOverride | null> {
  if (await useSqlite()) {
    const rows = await query(
      'SELECT ui_json, effect_code, bridge_config FROM effect_overrides WHERE effect_id = ?',
      [effectId],
    )
    if (rows.length === 0) return null
    const row = rows[0]
    return {
      uiJson: row.ui_json as string,
      effectCode: row.effect_code as string,
      bridgeConfig: row.bridge_config as string | undefined,
    }
  }
  const raw = localStorage.getItem(`${LS_PREFIX}${effectId}`)
  return raw ? (JSON.parse(raw) as EffectOverride) : null
}

export async function resetEffectOverride(effectId: string): Promise<void> {
  if (await useSqlite()) {
    await execute('DELETE FROM effect_overrides WHERE effect_id = ?', [effectId])
    return
  }
  localStorage.removeItem(`${LS_PREFIX}${effectId}`)
}

export async function hasEffectOverride(effectId: string): Promise<boolean> {
  if (await useSqlite()) {
    const rows = await query(
      'SELECT 1 FROM effect_overrides WHERE effect_id = ?',
      [effectId],
    )
    return rows.length > 0
  }
  return localStorage.getItem(`${LS_PREFIX}${effectId}`) !== null
}
