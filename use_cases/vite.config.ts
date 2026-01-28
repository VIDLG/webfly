import { defineConfig, Plugin, loadEnv } from 'vite';
import react from '@vitejs/plugin-react-swc';
import { qrcode } from 'vite-plugin-qrcode';
import qrcodeTerminal from 'qrcode-terminal';
import os from 'os';
import net from 'net';

// Helper to find next available port
const getAvailablePort = async (startPort: number): Promise<number> => {
  const isPortAvailable = (port: number) => {
    return new Promise((resolve) => {
      const server = net.createServer();
      server.unref();
      server.on('error', () => resolve(false));
      server.listen(port, () => {
        server.close(() => resolve(true));
      });
    });
  };

  let port = startPort;
  while (!(await isPortAvailable(port))) {
    port++;
    if (port > startPort + 100) throw new Error('No available port found');
  }
  return port;
};

// Helper to get local IP
const getLocalIP = () => {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]!) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
};

// https://vitejs.dev/config/
export default defineConfig(async ({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const ip = env.HOST_IP || getLocalIP();
  const port = await getAvailablePort(5173); // Start checking from 5173
  const targetUrl = `https://app.zhihaohuoyun.com/route/${ip}.${port}/`;
  const basePath = `/route/${ip}.${port}/`;

  const customQrcode = (): Plugin => {
    return {
      name: 'custom-qrcode',
      configureServer(server) {
        const _printUrls = server.printUrls;
        server.printUrls = () => {
          _printUrls();
          console.log(`\n  ➜  App Route: \x1b[36m${targetUrl}\x1b[0m`);
          qrcodeTerminal.generate(targetUrl, { small: true });
        };
      },
    };
  };

  return {
    base: basePath, // Use path-only base to allow access from both Local and Proxy
    plugins: [react(), qrcode(), customQrcode()],
    publicDir: 'public',
    build: {
      // Keep CRA-compatible output folder name
      outDir: 'build',
      emptyOutDir: true,
    },
    define: {
      // Provide NODE_ENV for libs expecting it
      'process.env.NODE_ENV': JSON.stringify(
        mode === 'production' ? 'production' : 'development'
      ),
    },
    server: {
      port, // Force the port we found
      strictPort: true,
      host: true,
      allowedHosts: ['app.zhihaohuoyun.com'],
      cors: true, // Enable CORS for proxy access
    },
  };
});

