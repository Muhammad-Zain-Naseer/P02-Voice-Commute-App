/**
 * Socket.IO Configuration
 * Defines CORS settings and connection options for real-time communication
 */

const socketConfig = {
  cors: {
    origin: process.env.CLIENT_URL || "*",
    methods: ["GET", "POST"],
    credentials: true
  },
  // Connection state recovery helps clients reconnect after brief disconnections
  connectionStateRecovery: {
    maxDisconnectionDuration: 2 * 60 * 1000, // 2 minutes
    skipMiddlewares: true
  },
  // Ping timeout and interval for detecting disconnected clients
  pingTimeout: 60000,
  pingInterval: 25000
};

export default socketConfig;
