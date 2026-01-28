import { defineConfig, loadEnv } from 'vite'
import type { Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import { qrcode } from 'vite-plugin-qrcode'
import tailwindcss from 'tailwindcss'
import autoprefixer from 'autoprefixer'
import qrcodeTerminal from 'qrcode-terminal'
import os from 'os'
import net from 'net'

// Helper to find next available port
const getAvailablePort = async (startPort: number): Promise<number> => {
  const isPortAvailable = (port: number) => {
    return new Promise((resolve) => {
      const server = net.createServer()
      server.unref()
      server.on('error', () => resolve(false))
      server.listen(port, () => {
        server.close(() => resolve(true))
      })
    })
  }

  let port = startPort
  while (!(await isPortAvailable(port))) {
    port++
    if (port > startPort + 100) throw new Error('No available port found')
  }
  return port
}

// Helper to get local IP
const getLocalIP = () => {
  const interfaces = os.networkInterfaces()
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]!) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address
      }
    }
  }
  return '127.0.0.1'
}

// https://vite.dev/config/
export default defineConfig(async ({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const ip = env.HOST_IP || getLocalIP()
  const port = await getAvailablePort(5173) // Start checking from 5173
  const targetUrl = `https://app.zhihaohuoyun.com/route/${ip}.${port}/`

  const customQrcode = (): Plugin => {
    return {
      name: 'custom-qrcode',
      configureServer(server) {
        // We handle printing URL ourselves since we know the correct one now
        const _printUrls = server.printUrls
        server.printUrls = () => {
            _printUrls()
            console.log(`\n  ➜  App Route: \x1b[36m${targetUrl}\x1b[0m`)
            qrcodeTerminal.generate(targetUrl, { small: true })
        }
      },
    }
  }

  return {
    base: targetUrl, // Adaptive base path!
    plugins: [
      react({
        babel: {
          plugins: [['babel-plugin-react-compiler']],
        },
      }),
      qrcode(),
      customQrcode(),
    ],
    build: {
      rollupOptions: {
        output: {
          manualChunks(id: string) {
            if (!id.includes('node_modules')) return

            // Keep large/rarely-needed deps isolated.
            if (id.includes('@babel/standalone')) return 'babel'

            // Core UI runtime.
            if (id.includes('/react/') || id.includes('/react-dom/')) return 'react'

            // WebF-related deps.
            if (id.includes('/@openwebf/')) return 'openwebf'

            return 'vendor'
          },
        },
      },
    },
    css: {
      postcss: {
        plugins: [
          tailwindcss,
          autoprefixer,
        ],
      },
    },
    server: {
      port, // Force the port we found
      strictPort: true, // Fail if port is busy (it shouldn't be, we just checked)
      host: true, // Listen on all addresses
      allowedHosts: ['app.zhihaohuoyun.com'],
    },
  }
})
