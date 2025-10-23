import logger from "../utils/logger.js";

/**
 * Global error handler middleware
 */
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.error(`Error: ${err.message}`, {
    stack: err.stack,
    path: req.path,
    method: req.method
  });

  // Handle Multer errors
  if (err.name === "MulterError") {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        error: "File size too large. Maximum size is 100MB."
      });
    }
    return res.status(400).json({
      success: false,
      error: `File upload error: ${err.message}`
    });
  }

  // Handle file type errors
  if (err.message && err.message.includes("Invalid file type")) {
    return res.status(400).json({
      success: false,
      error: err.message
    });
  }

  // Handle AssemblyAI API errors
  if (err.message && err.message.includes("AssemblyAI")) {
    return res.status(502).json({
      success: false,
      error: "Transcription service error. Please try again later.",
      details: process.env.NODE_ENV === "development" ? err.message : undefined
    });
  }

  // Handle validation errors
  if (err.name === "ValidationError") {
    return res.status(400).json({
      success: false,
      error: "Validation error",
      details: err.message
    });
  }

  // Default error response
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    error: err.message || "Internal server error",
    ...(process.env.NODE_ENV === "development" && { stack: err.stack })
  });
};

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res) => {
  logger.warn(`404 Not Found: ${req.method} ${req.path}`);
  res.status(404).json({
    success: false,
    error: `Route not found: ${req.method} ${req.path}`
  });
};

export { errorHandler, notFoundHandler };
