/**
 * RideRequest Model
 * Represents a ride request from a commuter
 */

import { v4 as uuidv4 } from "uuid";

class RideRequest {
  constructor({
    userId,
    userType = "commuter",
    userName,
    source,
    destination,
    socketId,
    sourceCoordinates = null,
    destinationCoordinates = null
  }) {
    this.id = uuidv4();
    this.userId = userId;
    this.userType = userType; // 'commuter' or 'driver'
    this.userName = userName || "Anonymous User";
    this.source = {
      address: source,
      coordinates: sourceCoordinates
    };
    this.destination = {
      address: destination,
      coordinates: destinationCoordinates
    };
    this.status = "pending"; // 'pending', 'matched', 'cancelled', 'completed'
    this.socketId = socketId;
    this.matchedWith = null; // Will contain driver info when matched
    this.createdAt = new Date().toISOString();
    this.updatedAt = new Date().toISOString();
  }

  /**
   * Update ride status
   */
  updateStatus(newStatus) {
    this.status = newStatus;
    this.updatedAt = new Date().toISOString();
  }

  /**
   * Match with a driver
   */
  matchWith(driverData) {
    this.matchedWith = {
      driverId: driverData.driverId,
      driverName: driverData.driverName,
      socketId: driverData.socketId,
      matchedAt: new Date().toISOString()
    };
    this.updateStatus("matched");
  }

  /**
   * Convert to JSON for client response
   */
  toJSON() {
    return {
      id: this.id,
      userId: this.userId,
      userType: this.userType,
      userName: this.userName,
      source: this.source,
      destination: this.destination,
      status: this.status,
      matchedWith: this.matchedWith,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

export default RideRequest;
