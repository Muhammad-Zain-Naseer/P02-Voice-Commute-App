import OTP from "../models/OTP.js";
import logger from "../utils/logger.js";

class OTPService {
  generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async sendOTP(phoneNumber) {
    try {
      await OTP.deleteMany({ phoneNumber });

      const otpCode = this.generateOTP();

      const otp = new OTP({
        phoneNumber,
        otp: otpCode
      });
      await otp.save();

      // Development mode - log OTP
      if (process.env.NODE_ENV === "development") {
        logger.info(`📱 OTP for ${phoneNumber}: ${otpCode}`);
      }

      return {
        success: true,
        message: "OTP sent successfully"
      };
    } catch (error) {
      logger.error("Error sending OTP:", error);
      throw new Error("Failed to send OTP");
    }
  }

  async verifyOTP(phoneNumber, otpCode) {
    let otpRecord = null;
    try {
      const otpRecord = await OTP.findOne({
        phoneNumber,
        otp: otpCode,
        verified: false
      }).sort({ createdAt: -1 });

      if (!otpRecord) {
        return {
          success: false,
          message: "Invalid or expired OTP"
        };
      }

      if (otpRecord.attempts >= 3) {
        await OTP.deleteOne({ _id: otpRecord._id });
        return {
          success: false,
          message: "Too many attempts. Please request a new OTP."
        };
      }

      otpRecord.verified = true;
      await otpRecord.save();

      return {
        success: true,
        message: "OTP verified successfully"
      };
    } catch (error) {
      logger.error("Error verifying OTP:", error);

      if (otpRecord) {
        otpRecord.attempts += 1;
        await otpRecord.save();
      }

      throw new Error("Failed to verify OTP");
    }
  }
}

export default new OTPService();
