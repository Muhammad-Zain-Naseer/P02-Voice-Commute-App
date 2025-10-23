import geminiService from "../services/gemini.service.js";
import logger from "../utils/logger.js";

class AudioController {
  /**
   * Process audio directly with Gemini
   * POST /api/audio/process
   */
  async processAudio(req, res, next) {
    try {
      // Check if file was uploaded
      if (!req.file) {
        return res.status(400).json({
          success: false,
          error: "No audio file provided. Please upload an audio file."
        });
      }

      if (!geminiService.isAvailable()) {
        return res.status(503).json({
          success: false,
          error:
            "Gemini service is not available. Please configure GEMINI_API_KEY."
        });
      }

      logger.info(`Processing audio with Gemini: ${req.file.originalname}`);

      // Process audio directly with Gemini
      const locations = await geminiService.extractLocationsFromAudio(
        req.file.path
      );

      res.status(200).json({
        success: true,
        data: {
          status: "completed",
          locations: locations
        }
      });
    } catch (error) {
      logger.error(`Error in processAudio controller: ${error.message}`);
      next(error);
    }
  }

  /**
   * Health check for audio service
   * GET /api/audio/health
   */
  async healthCheck(req, res) {
    res.status(200).json({
      success: true,
      message: "Audio processing service is running",
      service: "Gemini"
    });
  }
}

export default new AudioController();
