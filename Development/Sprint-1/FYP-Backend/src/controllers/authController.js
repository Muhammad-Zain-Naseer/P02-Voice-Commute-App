import User from "../models/User.js";
import otpService from "../services/otpService.js";
import jwt from "jsonwebtoken";
import config from "../config/env.config.js";
import logger from "../utils/logger.js";

class AuthController {
  // Request OTP for signup
  async requestSignupOTP(req, res) {
    try {
      let { phoneNumber } = req.body;

      if (!phoneNumber) {
        return res.status(400).json({
          success: false,
          message: "Phone number is required"
        });
      }

      phoneNumber = User.formatPhoneNumber(phoneNumber);

      const existingUser = await User.findOne({ phoneNumber });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: "User already exists. Please login."
        });
      }

      await otpService.sendOTP(phoneNumber);

      res.status(200).json({
        success: true,
        message: "OTP sent to your phone number",
        phoneNumber
      });
    } catch (error) {
      logger.error("Error in requestSignupOTP:", error);
      res.status(500).json({
        success: false,
        message: "Failed to send OTP"
      });
    }
  }

  // Complete signup
  async completeSignup(req, res) {
    try {
      let { phoneNumber, otp, pin, role } = req.body;

      if (!phoneNumber || !otp || !pin) {
        return res.status(400).json({
          success: false,
          message: "Phone number, OTP, and PIN are required"
        });
      }

      if (!/^\d{4}$/.test(pin)) {
        return res.status(400).json({
          success: false,
          message: "PIN must be exactly 4 digits"
        });
      }

      phoneNumber = User.formatPhoneNumber(phoneNumber);

      const otpVerification = await otpService.verifyOTP(phoneNumber, otp);
      if (!otpVerification.success) {
        return res.status(400).json(otpVerification);
      }

      const user = new User({
        phoneNumber,
        pin,
        role: role || "commuter",
        isVerified: true
      });

      await user.save();

      const token = this.generateToken(user._id);

      res.status(201).json({
        success: true,
        message: "Account created successfully",
        data: {
          user: {
            id: user._id,
            phoneNumber: user.phoneNumber,
            role: user.role
          },
          token
        }
      });
    } catch (error) {
      logger.error("Error in completeSignup:", error);
      res.status(500).json({
        success: false,
        message: "Failed to create account"
      });
    }
  }

  // Login
  async login(req, res) {
    try {
      let { phoneNumber, pin } = req.body;

      if (!phoneNumber || !pin) {
        return res.status(400).json({
          success: false,
          message: "Phone number and PIN are required"
        });
      }

      phoneNumber = User.formatPhoneNumber(phoneNumber);

      const user = await User.findOne({ phoneNumber });
      if (!user) {
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or PIN"
        });
      }

      const isPinValid = await user.comparePin(pin);
      if (!isPinValid) {
        return res.status(401).json({
          success: false,
          message: "Invalid phone number or PIN"
        });
      }

      user.lastLogin = new Date();
      await user.save();

      const token = this.generateToken(user._id);

      res.status(200).json({
        success: true,
        message: "Login successful",
        data: {
          user: {
            id: user._id,
            phoneNumber: user.phoneNumber,
            role: user.role
          },
          token
        }
      });
    } catch (error) {
      logger.error("Error in login:", error);
      res.status(500).json({
        success: false,
        message: "Login failed"
      });
    }
  }

  // Generate JWT
  generateToken(userId) {
    return jwt.sign({ userId }, config.jwtSecret, {
      expiresIn: config.jwtExpire
    });
  }
}

export default new AuthController();
