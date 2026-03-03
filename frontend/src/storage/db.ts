/**
 * Shared database initialization for effects.db.
 *
 * Uses WebF's sqflite module via invokeModuleAsync.
 * The webf_sqflite module uses structured options objects — see
 * sq_flite_module_bindings_generated.dart for the Dart-side API.
 *
 * Tables:
 *   - effect_overrides: AI-modified effect code + UI overrides
 *   - ai_config: API key, model preferences
 */

interface WebFGlobal {
  invokeModuleAsync(module: string, method: string, ...args: unknown[]): Promise<unknown>
}

function getWebF(): WebFGlobal | null {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const w = globalThis as any
  return w.webf ?? null
}

/** Result types matching the Dart-side generated bindings */
interface OpenDatabaseResult {
  success: string
  databaseId?: string
  path?: string
  version?: number
  error?: string
}

interface RawQueryResult {
  success: string
  rows?: string   // JSON-encoded array of row objects
  count?: number
  error?: string
}

interface ExecuteResult {
  success: string
  error?: string
}

let dbInitPromise: Promise<string> | null = null

const DB_NAME = 'effects.db'

const INIT_SQL = [
  `CREATE TABLE IF NOT EXISTS effect_overrides (
    effect_id     TEXT PRIMARY KEY,
    ui_json       TEXT NOT NULL,
    effect_code   TEXT NOT NULL,
    bridge_config TEXT,
    updated_at    TEXT DEFAULT CURRENT_TIMESTAMP
  )`,
  `CREATE TABLE IF NOT EXISTS ai_config (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )`,
]

/**
 * Open (or create) the shared effects.db and ensure tables exist.
 * Returns the databaseId handle used by sqflite for subsequent operations.
 *
 * Falls back to null if WebF sqflite is not available (e.g. in dev mode).
 */
export async function getDatabase(): Promise<string | null> {
  const webf = getWebF()
  if (!webf) return null

  if (!dbInitPromise) {
    dbInitPromise = (async () => {
      const result = await webf.invokeModuleAsync(
        'SQFlite', 'openDatabase', { path: DB_NAME },
      ) as OpenDatabaseResult

      if (result.success !== 'true' && result.success !== '1') {
        throw new Error(`Failed to open database: ${result.error ?? 'unknown error'}`)
      }

      const databaseId = result.databaseId
      if (!databaseId) {
        throw new Error('openDatabase did not return a databaseId')
      }

      for (const sql of INIT_SQL) {
        const execResult = await webf.invokeModuleAsync(
          'SQFlite', 'execute', { databaseId, sql },
        ) as ExecuteResult

        if (execResult.success !== 'true' && execResult.success !== '1') {
          throw new Error(`Failed to execute init SQL: ${execResult.error ?? sql}`)
        }
      }

      return databaseId
    })()
  }

  return dbInitPromise
}

/**
 * Execute a raw SQL query. Returns rows as an array of objects.
 */
export async function query(sql: string, args: unknown[] = []): Promise<Record<string, unknown>[]> {
  const databaseId = await getDatabase()
  if (!databaseId) return []

  const webf = getWebF()!
  const result = await webf.invokeModuleAsync(
    'SQFlite', 'rawQuery',
    { databaseId, sql, arguments: args.length > 0 ? args : undefined },
  ) as RawQueryResult

  if (result.success !== 'true' && result.success !== '1') {
    throw new Error(`rawQuery failed: ${result.error ?? 'unknown error'}`)
  }

  if (!result.rows) return []

  // rows is JSON-encoded string from the Dart side
  try {
    return JSON.parse(result.rows) as Record<string, unknown>[]
  } catch {
    return []
  }
}

/**
 * Execute a SQL statement (INSERT, UPDATE, DELETE).
 */
export async function execute(sql: string, args: unknown[] = []): Promise<void> {
  const databaseId = await getDatabase()
  if (!databaseId) return

  const webf = getWebF()!
  const result = await webf.invokeModuleAsync(
    'SQFlite', 'execute',
    { databaseId, sql, arguments: args.length > 0 ? args : undefined },
  ) as ExecuteResult

  if (result.success !== 'true' && result.success !== '1') {
    throw new Error(`execute failed: ${result.error ?? 'unknown error'}`)
  }
}
