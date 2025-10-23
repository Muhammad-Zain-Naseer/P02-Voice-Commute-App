import express from "express";
import authController from "../controllers/authController.js";
import { authenticate } from "../middleware/auth.js";

const router = express.Router();

// Signup
router.post("/signup/request-otp", authController.requestSignupOTP);
router.post("/signup/verify", authController.completeSignup);

// Login
router.post("/login", authController.login);

// Protected route (test)
router.get("/me", authenticate, (req, res) => {
  res.status(200).json({
    success: true,
    data: {
      user: req.user
    }
  });
});

export default router;
