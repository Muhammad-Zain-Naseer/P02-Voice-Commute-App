/**
 * Ride Routes
 * REST API endpoints for ride management
 */

import express from "express";
import rideController from "../controllers/ride.controller.js";

const router = express.Router();

/**
 * @route   GET /api/rides/stats
 * @desc    Get connection pool statistics
 * @access  Public
 */
router.get("/stats", rideController.getStats);

/**
 * @route   GET /api/rides/pending
 * @desc    Get all pending (available) rides
 * @access  Public
 */
router.get("/pending", rideController.getPendingRides);

/**
 * @route   POST /api/rides
 * @desc    Create a new ride request
 * @access  Public
 * @body    {source, destination, userId?, userName?, sourceCoordinates?, destinationCoordinates?}
 */
router.post("/", rideController.createRide);

/**
 * @route   GET /api/rides
 * @desc    Get all rides (with optional filters)
 * @access  Public
 * @query   status?, userId?
 */
router.get("/", rideController.getRides);

/**
 * @route   GET /api/rides/:id
 * @desc    Get a specific ride by ID
 * @access  Public
 */
router.get("/:id", rideController.getRide);

/**
 * @route   POST /api/rides/:id/match
 * @desc    Match a ride with a driver
 * @access  Public
 * @body    {driverId, driverName?}
 */
router.post("/:id/match", rideController.matchRide);

/**
 * @route   DELETE /api/rides/:id
 * @desc    Cancel a ride
 * @access  Public
 */
router.delete("/:id", rideController.cancelRide);

export default router;
