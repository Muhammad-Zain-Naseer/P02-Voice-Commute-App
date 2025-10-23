import express from "express";
import { createServer } from "http";
import { Server } from "socket.io";
import cors from "cors";
import config from "../config/env.config.js";
import socketConfig from "../config/socket.config.js";
import logger from "../utils/logger.js";
import audioRoutes from "../routes/audio.routes.js";
import rideRoutes from "../routes/ride.routes.js";
import authRoutes from "../routes/authRoutes.js";
import connectDB from "../config/db.js";
import dotenv from "dotenv";
import {
  errorHandler,
  notFoundHandler
} from "../middleware/errorHandler.middleware.js";
import { handleRideEvents } from "../sockets/ride.socket.js";

dotenv.config();
connectDB();

const app = express();

// Create HTTP server
const httpServer = createServer(app);

// Initialize Socket.IO with configuration
const io = new Server(httpServer, socketConfig);

// Enable CORS for all origins (for development)
app.use(cors());

app.use(express.json());

// Health check endpoint
app.get("/", (req, res) => {
  logger.info("Health check endpoint accessed");
  res.json({
    message: "Server is running!",
    features: ["Audio Processing", "Real-time Ride Matching"],
    socketEnabled: true
  });
});

// API Routes
app.use("/api/audio", audioRoutes);
app.use("/api/rides", rideRoutes);

// Socket.IO connection handling
io.on("connection", (socket) => {
  logger.info(`🔌 Socket connected: ${socket.id}`);

  // Setup ride event handlers
  handleRideEvents(io, socket);

  socket.on("disconnect", (reason) => {
    logger.info(`🔌 Socket disconnected: ${socket.id} | Reason: ${reason}`);
  });
});

app.use("/api/auth", authRoutes);

// 404 handler - must be after all routes
app.use(notFoundHandler);

// Error handler - must be last
app.use(errorHandler);

// Start server with Socket.IO support
httpServer.listen(config.port, () => {
  logger.info(
    `🚀 Server running on port ${config.port} in ${config.nodeEnv} mode`
  );
  logger.info(`📡 Socket.IO enabled and ready for connections`);
  logger.info(`🔗 WebSocket URL: ws://localhost:${config.port}`);
});
