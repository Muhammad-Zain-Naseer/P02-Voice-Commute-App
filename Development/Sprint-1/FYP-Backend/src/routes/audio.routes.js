import express from "express";
import audioController from "../controllers/audio.controller.js";
import upload from "../middleware/upload.middleware.js";

const router = express.Router();

/**
 * @route   POST /api/audio/process
 * @desc    Process audio and extract locations using Gemini
 * @access  Public
 * @body    {file} audio - Audio file to process
 */
router.post("/process", upload.single("audio"), audioController.processAudio);

/**
 * @route   GET /api/audio/health
 * @desc    Health check for audio service
 * @access  Public
 */
router.get("/health", audioController.healthCheck);

export default router;
