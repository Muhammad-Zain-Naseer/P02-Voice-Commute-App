/**
 * Connection Pool Service
 * Manages active ride requests and connected users in memory
 */

import logger from "../utils/logger.js";
import RideRequest from "../models/RideRequest.js";

class ConnectionPoolService {
  constructor() {
    // Store all active rides: Map<rideId, RideRequest>
    this.rides = new Map();

    // Store connected users: Map<socketId, userData>
    this.users = new Map();

    logger.info("Connection Pool Service initialized");
  }

  /**
   * Add a new ride to the pool
   * @param {Object} rideData - Ride request data
   * @returns {RideRequest} - Created ride request
   */
  addRide(rideData) {
    const ride = new RideRequest(rideData);
    this.rides.set(ride.id, ride);

    logger.info(
      `Ride added to pool: ${ride.id} | From: ${ride.source.address} → To: ${ride.destination.address}`
    );
    logger.info(`Total rides in pool: ${this.rides.size}`);

    return ride;
  }

  /**
   * Remove a ride from the pool
   * @param {string} rideId - Ride ID to remove
   * @returns {boolean} - True if removed, false if not found
   */
  removeRide(rideId) {
    const ride = this.rides.get(rideId);
    if (ride) {
      this.rides.delete(rideId);
      logger.info(`Ride removed from pool: ${rideId}`);
      logger.info(`Total rides in pool: ${this.rides.size}`);
      return true;
    }

    logger.warn(`Attempted to remove non-existent ride: ${rideId}`);
    return false;
  }

  /**
   * Get a specific ride by ID
   * @param {string} rideId - Ride ID
   * @returns {RideRequest|null} - Ride request or null
   */
  getRide(rideId) {
    return this.rides.get(rideId) || null;
  }

  /**
   * Get all rides or filtered rides
   * @param {Object} filters - Optional filters (status, userId, etc.)
   * @returns {Array<RideRequest>} - Array of ride requests
   */
  getRides(filters = {}) {
    let ridesArray = Array.from(this.rides.values());

    // Apply filters
    if (filters.status) {
      ridesArray = ridesArray.filter((ride) => ride.status === filters.status);
    }

    if (filters.userId) {
      ridesArray = ridesArray.filter((ride) => ride.userId === filters.userId);
    }

    // Sort by creation time (newest first)
    ridesArray.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return ridesArray;
  }

  /**
   * Get all pending rides (available for matching)
   * @returns {Array<RideRequest>} - Array of pending ride requests
   */
  getPendingRides() {
    return this.getRides({ status: "pending" });
  }

  /**
   * Match a ride with a driver
   * @param {string} rideId - Ride ID to match
   * @param {Object} driverData - Driver information
   * @returns {RideRequest|null} - Updated ride or null if not found
   */
  matchRide(rideId, driverData) {
    const ride = this.rides.get(rideId);

    if (!ride) {
      logger.warn(`Cannot match non-existent ride: ${rideId}`);
      return null;
    }

    if (ride.status !== "pending") {
      logger.warn(`Cannot match ride ${rideId} with status: ${ride.status}`);
      return null;
    }

    ride.matchWith(driverData);
    logger.info(`Ride matched: ${rideId} with driver: ${driverData.driverId}`);

    return ride;
  }

  /**
   * Cancel a ride
   * @param {string} rideId - Ride ID to cancel
   * @returns {RideRequest|null} - Updated ride or null
   */
  cancelRide(rideId) {
    const ride = this.rides.get(rideId);

    if (!ride) {
      logger.warn(`Cannot cancel non-existent ride: ${rideId}`);
      return null;
    }

    ride.updateStatus("cancelled");
    logger.info(`Ride cancelled: ${rideId}`);

    // Remove from pool after a short delay to allow clients to receive update
    setTimeout(() => {
      this.removeRide(rideId);
    }, 2000);

    return ride;
  }

  /**
   * Add a user to the connection pool
   * @param {string} socketId - Socket ID
   * @param {Object} userData - User information
   */
  addUser(socketId, userData) {
    this.users.set(socketId, {
      ...userData,
      socketId,
      connectedAt: new Date().toISOString()
    });

    logger.info(
      `User connected: ${userData.userName || userData.userId} (${socketId})`
    );
    logger.info(`Total connected users: ${this.users.size}`);
  }

  /**
   * Remove a user and their associated rides
   * @param {string} socketId - Socket ID
   */
  removeUser(socketId) {
    const user = this.users.get(socketId);

    if (user) {
      // Find and cancel all rides associated with this user
      const userRides = Array.from(this.rides.values()).filter(
        (ride) => ride.socketId === socketId
      );

      userRides.forEach((ride) => {
        this.cancelRide(ride.id);
      });

      this.users.delete(socketId);
      logger.info(
        `User disconnected: ${user.userName || user.userId} (${socketId})`
      );
      logger.info(
        `Cancelled ${userRides.length} ride(s) for disconnected user`
      );
      logger.info(`Total connected users: ${this.users.size}`);
    }
  }

  /**
   * Get a user by socket ID
   * @param {string} socketId - Socket ID
   * @returns {Object|null} - User data or null
   */
  getUser(socketId) {
    return this.users.get(socketId) || null;
  }

  /**
   * Get statistics about the connection pool
   * @returns {Object} - Pool statistics
   */
  getStats() {
    return {
      totalRides: this.rides.size,
      pendingRides: this.getPendingRides().length,
      matchedRides: this.getRides({ status: "matched" }).length,
      connectedUsers: this.users.size,
      timestamp: new Date().toISOString()
    };
  }
}

// Export singleton instance
export default new ConnectionPoolService();
