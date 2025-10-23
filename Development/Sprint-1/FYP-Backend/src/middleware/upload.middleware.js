import multer from "multer";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, "../../uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname)
    );
  }
});

// File filter to accept only audio files
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    "audio/mpeg", // mp3
    "audio/wav", // wav
    "audio/wave", // wav alternative
    "audio/x-wav", // wav alternative
    "audio/mp4", // m4a
    "audio/x-m4a", // m4a alternative
    "audio/aac", // aac
    "audio/flac", // flac
    "audio/ogg", // ogg
    "audio/webm", // webm
    "video/mp4", // mp4 (for audio extraction)
    "video/webm" // webm video
  ];

  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new Error(
        `Invalid file type. Only audio files are allowed. Received: ${file.mimetype}`
      ),
      false
    );
  }
};

// Configure multer with limits
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB max file size
  }
});

export default upload;
