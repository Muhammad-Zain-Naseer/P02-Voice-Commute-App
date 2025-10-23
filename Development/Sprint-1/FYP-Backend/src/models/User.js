import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema({
  phoneNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  pin: {
    type: String,
    required: true,
    minlength: 4,
    maxlength: 4
  },
  role: {
    type: String,
    enum: ["commuter", "driver", "admin"],
    default: "commuter"
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastLogin: {
    type: Date
  }
});

// Hash PIN before saving
userSchema.pre("save", async function (next) {
  if (!this.isModified("pin")) return next();
  const salt = await bcrypt.genSalt(10);
  this.pin = await bcrypt.hash(this.pin, salt);
  next();
});

// Compare PIN method
userSchema.methods.comparePin = async function (candidatePin) {
  return await bcrypt.compare(candidatePin, this.pin);
};

// Format phone number
userSchema.statics.formatPhoneNumber = function (phone) {
  phone = phone.replace(/[\s-]/g, "");

  if (phone.startsWith("0")) {
    phone = "+92" + phone.substring(1);
  } else if (!phone.startsWith("+92")) {
    phone = "+92" + phone;
  }

  return phone;
};

export default mongoose.model("User", userSchema);
