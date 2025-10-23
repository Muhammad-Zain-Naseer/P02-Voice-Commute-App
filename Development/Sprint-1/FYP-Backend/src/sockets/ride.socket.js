/**
 * Socket Event Handlers for Ride Matching System
 * Handles real-time ride requests, matching, and updates
 */

import connectionPoolService from "../services/connectionPool.service.js";
import logger from "../utils/logger.js";

/**
 * Setup ride-related socket event handlers
 * @param {Server} io - Socket.IO server instance
 * @param {Socket} socket - Individual socket connection
 */
export const handleRideEvents = (io, socket) => {
  logger.info(`Setting up ride event handlers for socket: ${socket.id}`);

  /**
   * Handle user connection initialization
   * Client sends user data when connecting
   */
  socket.on("user:register", (userData) => {
    try {
      logger.info(`User registration: ${JSON.stringify(userData)}`);

      // Add user to connection pool
      connectionPoolService.addUser(socket.id, {
        userId: userData.userId || socket.id,
        userName: userData.userName || "Anonymous User",
        userType: userData.userType || "commuter"
      });

      // Send acknowledgment with pool stats
      const stats = connectionPoolService.getStats();
      socket.emit("user:registered", {
        success: true,
        socketId: socket.id,
        stats
      });

      logger.info(`User registered successfully: ${socket.id}`);
    } catch (error) {
      logger.error(`Error in user:register: ${error.message}`);
      socket.emit("error", {
        event: "user:register",
        message: "Failed to register user"
      });
    }
  });

  /**
   * Handle new ride creation
   * Commuter creates a ride request with source and destination
   */
  socket.on("ride:create", (rideData) => {
    try {
      logger.info(`Ride creation request: ${JSON.stringify(rideData)}`);

      // Validate ride data
      if (!rideData.source || !rideData.destination) {
        socket.emit("ride:error", {
          message: "Source and destination are required"
        });
        return;
      }

      // Get user from connection pool
      const user = connectionPoolService.getUser(socket.id);

      // Add ride to connection pool
      const ride = connectionPoolService.addRide({
        userId: user?.userId || socket.id,
        userName: user?.userName || rideData.userName || "Anonymous User",
        userType: "commuter",
        source: rideData.source,
        destination: rideData.destination,
        sourceCoordinates: rideData.sourceCoordinates || null,
        destinationCoordinates: rideData.destinationCoordinates || null,
        socketId: socket.id
      });

      // Notify the commuter that ride was created
      socket.emit("ride:created", {
        success: true,
        ride: ride.toJSON()
      });

      // Broadcast new ride to all connected drivers
      socket.broadcast.emit("ride:new", {
        ride: ride.toJSON()
      });

      logger.info(`Ride created and broadcasted: ${ride.id}`);
    } catch (error) {
      logger.error(`Error in ride:create: ${error.message}`);
      socket.emit("ride:error", {
        message: "Failed to create ride request"
      });
    }
  });

  /**
   * Handle ride list request
   * Drivers request list of all available rides
   */
  socket.on("ride:list", () => {
    try {
      logger.info(`Ride list requested by: ${socket.id}`);

      // Get pending rides by default
      const rides = connectionPoolService.getPendingRides();

      socket.emit("ride:list", {
        success: true,
        rides: rides.map((ride) => ride.toJSON()),
        count: rides.length
      });

      logger.info(`Sent ${rides.length} pending rides to ${socket.id}`);
    } catch (error) {
      logger.error(`Error in ride:list: ${error.message}`);
      socket.emit("ride:error", {
        message: "Failed to fetch ride list"
      });
    }
  });

  /**
   * Handle ride matching
   * Driver accepts a ride request
   */
  socket.on("ride:match", (matchData) => {
    try {
      logger.info(`Ride match request: ${JSON.stringify(matchData)}`);

      const { rideId, driverId, driverName } = matchData;

      if (!rideId) {
        socket.emit("ride:error", {
          message: "Ride ID is required"
        });
        return;
      }

      // Get the ride
      const ride = connectionPoolService.getRide(rideId);

      if (!ride) {
        socket.emit("ride:error", {
          message: "Ride not found"
        });
        return;
      }

      if (ride.status !== "pending") {
        socket.emit("ride:error", {
          message: "Ride is no longer available"
        });
        return;
      }

      // Match the ride
      const matchedRide = connectionPoolService.matchRide(rideId, {
        driverId: driverId || socket.id,
        driverName: driverName || "Driver",
        socketId: socket.id
      });

      if (!matchedRide) {
        socket.emit("ride:error", {
          message: "Failed to match ride"
        });
        return;
      }

      // Notify the driver
      socket.emit("ride:matched", {
        success: true,
        ride: matchedRide.toJSON(),
        role: "driver"
      });

      // Notify the commuter
      io.to(matchedRide.socketId).emit("ride:matched", {
        success: true,
        ride: matchedRide.toJSON(),
        role: "commuter"
      });

      // Broadcast to all other clients that this ride is no longer available
      socket.broadcast.emit("ride:unavailable", {
        rideId: matchedRide.id
      });

      logger.info(
        `Ride matched successfully: ${rideId} with driver: ${socket.id}`
      );

      // Remove ride from pool after 5 seconds
      setTimeout(() => {
        connectionPoolService.removeRide(rideId);
      }, 5000);
    } catch (error) {
      logger.error(`Error in ride:match: ${error.message}`);
      socket.emit("ride:error", {
        message: "Failed to match ride"
      });
    }
  });

  /**
   * Handle ride cancellation
   * Commuter cancels their ride request
   */
  socket.on("ride:cancel", (data) => {
    try {
      logger.info(`Ride cancellation request: ${JSON.stringify(data)}`);

      const { rideId } = data;

      if (!rideId) {
        socket.emit("ride:error", {
          message: "Ride ID is required"
        });
        return;
      }

      // Get the ride
      const ride = connectionPoolService.getRide(rideId);

      if (!ride) {
        socket.emit("ride:error", {
          message: "Ride not found"
        });
        return;
      }

      // Check if the user owns this ride
      if (ride.socketId !== socket.id) {
        socket.emit("ride:error", {
          message: "You can only cancel your own rides"
        });
        return;
      }

      // Cancel the ride
      connectionPoolService.cancelRide(rideId);

      // Notify the commuter
      socket.emit("ride:cancelled", {
        success: true,
        rideId
      });

      // Broadcast to all clients
      socket.broadcast.emit("ride:cancelled", {
        rideId
      });

      logger.info(`Ride cancelled: ${rideId}`);
    } catch (error) {
      logger.error(`Error in ride:cancel: ${error.message}`);
      socket.emit("ride:error", {
        message: "Failed to cancel ride"
      });
    }
  });

  /**
   * Handle connection pool stats request
   */
  socket.on("pool:stats", () => {
    try {
      const stats = connectionPoolService.getStats();
      socket.emit("pool:stats", stats);
      logger.info(`Pool stats sent to ${socket.id}`);
    } catch (error) {
      logger.error(`Error in pool:stats: ${error.message}`);
    }
  });

  /**
   * Handle disconnection
   */
  socket.on("disconnect", () => {
    logger.info(`Client disconnecting: ${socket.id}`);

    // Remove user and their rides from pool
    connectionPoolService.removeUser(socket.id);

    // Broadcast updated ride list to all connected clients
    const pendingRides = connectionPoolService.getPendingRides();
    io.emit("ride:list:updated", {
      rides: pendingRides.map((ride) => ride.toJSON()),
      count: pendingRides.length
    });
  });
};
