import jwt from "jsonwebtoken";
import User from "../models/User.js";
import config from "../config/env.config.js";
import logger from "../utils/logger.js";

export const authenticate = async (req, res, next) => {
  try {
    const token = req.header("Authorization")?.replace("Bearer ", "");

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "No authentication token provided"
      });
    }

    const decoded = jwt.verify(token, config.jwtSecret);

    const user = await User.findById(decoded.userId).select("-pin");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User not found"
      });
    }

    req.user = user;
    next();
  } catch (error) {
    logger.error("Authentication error:", error);
    res.status(401).json({
      success: false,
      message: "Invalid or expired token"
    });
  }
};

export const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Not authenticated"
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to access this resource"
      });
    }

    next();
  };
};
