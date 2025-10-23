/**
 * Ride Controller
 * REST API endpoints for ride management (optional fallback to sockets)
 */

import connectionPoolService from "../services/connectionPool.service.js";
import logger from "../utils/logger.js";

class RideController {
  /**
   * Create a new ride request
   * POST /api/rides
   */
  async createRide(req, res, next) {
    try {
      const {
        userId,
        userName,
        source,
        destination,
        sourceCoordinates,
        destinationCoordinates
      } = req.body;

      // Validate input
      if (!source || !destination) {
        return res.status(400).json({
          success: false,
          error: "Source and destination are required"
        });
      }

      // Create ride
      const ride = connectionPoolService.addRide({
        userId: userId || "anonymous",
        userName: userName || "Anonymous User",
        userType: "commuter",
        source,
        destination,
        sourceCoordinates: sourceCoordinates || null,
        destinationCoordinates: destinationCoordinates || null,
        socketId: "rest-api" // Mark as REST API request
      });

      logger.info(`Ride created via REST API: ${ride.id}`);

      res.status(201).json({
        success: true,
        data: {
          ride: ride.toJSON()
        }
      });
    } catch (error) {
      logger.error(`Error in createRide: ${error.message}`);
      next(error);
    }
  }

  /**
   * Get all rides
   * GET /api/rides
   */
  async getRides(req, res, next) {
    try {
      const { status, userId } = req.query;

      const filters = {};
      if (status) {
        filters.status = status;
      }
      if (userId) {
        filters.userId = userId;
      }

      const rides = connectionPoolService.getRides(filters);

      logger.info(`Retrieved ${rides.length} rides via REST API`);

      res.status(200).json({
        success: true,
        data: {
          rides: rides.map((ride) => ride.toJSON()),
          count: rides.length
        }
      });
    } catch (error) {
      logger.error(`Error in getRides: ${error.message}`);
      next(error);
    }
  }

  /**
   * Get pending rides (available for matching)
   * GET /api/rides/pending
   */
  async getPendingRides(req, res, next) {
    try {
      const rides = connectionPoolService.getPendingRides();

      logger.info(`Retrieved ${rides.length} pending rides via REST API`);

      res.status(200).json({
        success: true,
        data: {
          rides: rides.map((ride) => ride.toJSON()),
          count: rides.length
        }
      });
    } catch (error) {
      logger.error(`Error in getPendingRides: ${error.message}`);
      next(error);
    }
  }

  /**
   * Get a specific ride by ID
   * GET /api/rides/:id
   */
  async getRide(req, res, next) {
    try {
      const { id } = req.params;

      const ride = connectionPoolService.getRide(id);

      if (!ride) {
        return res.status(404).json({
          success: false,
          error: "Ride not found"
        });
      }

      res.status(200).json({
        success: true,
        data: {
          ride: ride.toJSON()
        }
      });
    } catch (error) {
      logger.error(`Error in getRide: ${error.message}`);
      next(error);
    }
  }

  /**
   * Match a ride with a driver
   * POST /api/rides/:id/match
   */
  async matchRide(req, res, next) {
    try {
      const { id } = req.params;
      const { driverId, driverName } = req.body;

      if (!driverId) {
        return res.status(400).json({
          success: false,
          error: "Driver ID is required"
        });
      }

      const matchedRide = connectionPoolService.matchRide(id, {
        driverId,
        driverName: driverName || "Driver",
        socketId: "rest-api"
      });

      if (!matchedRide) {
        return res.status(404).json({
          success: false,
          error: "Ride not found or already matched"
        });
      }

      logger.info(`Ride matched via REST API: ${id}`);

      res.status(200).json({
        success: true,
        data: {
          ride: matchedRide.toJSON()
        }
      });
    } catch (error) {
      logger.error(`Error in matchRide: ${error.message}`);
      next(error);
    }
  }

  /**
   * Cancel a ride
   * DELETE /api/rides/:id
   */
  async cancelRide(req, res, next) {
    try {
      const { id } = req.params;

      const cancelledRide = connectionPoolService.cancelRide(id);

      if (!cancelledRide) {
        return res.status(404).json({
          success: false,
          error: "Ride not found"
        });
      }

      logger.info(`Ride cancelled via REST API: ${id}`);

      res.status(200).json({
        success: true,
        data: {
          ride: cancelledRide.toJSON()
        }
      });
    } catch (error) {
      logger.error(`Error in cancelRide: ${error.message}`);
      next(error);
    }
  }

  /**
   * Get connection pool statistics
   * GET /api/rides/stats
   */
  async getStats(req, res, next) {
    try {
      const stats = connectionPoolService.getStats();

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      logger.error(`Error in getStats: ${error.message}`);
      next(error);
    }
  }
}

export default new RideController();
