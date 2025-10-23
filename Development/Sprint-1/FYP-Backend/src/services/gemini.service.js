import { GoogleGenAI } from "@google/genai";
import fs from "fs";
import logger from "../utils/logger.js";

class GeminiService {
  constructor() {
    if (!process.env.GEMINI_API_KEY) {
      logger.warn(
        "GEMINI_API_KEY is not configured. Gemini features will be disabled."
      );
      this.client = null;
      return;
    }

    const apiKey = process.env.GEMINI_API_KEY;
    logger.info(
      `Gemini API Key configured: ${apiKey.substring(0, 10)}...${apiKey.substring(apiKey.length - 4)}`
    );

    this.client = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  }

  /**
   * Check if Gemini service is available
   * @returns {boolean}
   */
  isAvailable() {
    return this.client !== null;
  }

  /**
   * Extract source and destination locations from text
   * @param {string} text - Text in any language (Urdu, Hindi, English, etc.)
   * @returns {Promise<object>} Extracted locations
   */
  async extractLocations(text) {
    if (!this.isAvailable()) {
      throw new Error("Gemini API key is not configured");
    }

    try {
      logger.info(`Extracting locations from text: ${text}`);

      const prompt = `You are an AI assistant that extracts source and destination locations from text.

Text: "${text}"

Analyze this text and extract:
1. Source location (where the journey starts from)
2. Destination location (where the journey is going to)

The text may be in Urdu, Hindi, English, or any other language. Translate the locations to English.

Common Urdu/Hindi keywords:
- "سے" / "se" = from (indicates source)
- "کو" / "ko" = to (indicates destination)
- "جانا ہے" / "jana hai" = want to go
- "بک کروانی ہے" / "book karwani hai" = want to book

Respond ONLY in valid JSON format (no markdown, no code blocks):
{
  "source": "source location in English",
  "destination": "destination location in English",
  "original_text": "the exact text you understood from the input"
}

If you cannot find source or destination, use null for that field.`;

      const response = await this.client.models.generateContent({
        model: "gemini-2.5-flash",
        contents: prompt
      });

      const responseText = response.text.trim();

      // Clean the response (remove markdown code blocks if present)
      let cleanedResponse = responseText
        .replace(/```json\n?/g, "")
        .replace(/```\n?/g, "")
        .trim();

      // Parse JSON response
      const locationData = JSON.parse(cleanedResponse);

      // Return source, destination, and original text
      const result = {
        source: locationData.source,
        destination: locationData.destination,
        original_text: locationData.original_text || text
      };

      logger.info(
        `Locations extracted - Source: ${result.source}, Destination: ${result.destination}`
      );

      return result;
    } catch (error) {
      logger.error(`Gemini location extraction error: ${error.message}`);
      throw new Error(`Failed to extract locations: ${error.message}`);
    }
  }

  /**
   * Extract locations directly from audio file using Gemini
   * @param {string} audioFilePath - Path to audio file
   * @returns {Promise<object>} Extracted locations
   */
  async extractLocationsFromAudio(audioFilePath) {
    if (!this.isAvailable()) {
      throw new Error("Gemini API key is not configured");
    }

    try {
      logger.info(
        `Processing audio file directly with Gemini: ${audioFilePath}`
      );

      // Read audio file as base64
      const audioBuffer = fs.readFileSync(audioFilePath);
      const audioBase64 = audioBuffer.toString("base64");

      // Determine mime type based on file extension
      const mimeType = this.getMimeType(audioFilePath);

      const prompt = `Listen to this audio and extract the travel booking information.

Extract:
1. Source location (where the journey starts from) - Look for keywords like "سے" (se/from)
2. Destination location (where the journey is going to) - Look for keywords like "کو", "میں" (ko/mein/to/in), "جانا ہے" (jana hai/want to go)

CRITICAL RULES - MUST FOLLOW:
- ALWAYS include house numbers, flat numbers, building numbers in the destination field
- If audio says "مکان نمبر چار" (house number 4), destination MUST include "House Number 4"
- Extract the COMPLETE address with ALL details: house/flat number, street, area, city
- DO NOT drop house numbers or building numbers - they are essential
- Translate to English but keep all numbers exactly as mentioned
- If no source is explicitly mentioned (no "سے"/"se"/"from" keyword), set source to null

The audio may be in Urdu, Hindi, English, or any other language.

Common Urdu/Hindi keywords:
- "سے" / "se" = from (indicates SOURCE)
- "کو" / "ko" = to (indicates DESTINATION)
- "میں" / "mein" = in/at (indicates DESTINATION)
- "جانا ہے" / "jana hai" = want to go (indicates DESTINATION)
- "مکان نمبر" / "makaan number" = house number (part of address)

Respond ONLY in valid JSON format (no markdown, no code blocks):
{
  "source": "complete source address in English with all details OR null if not mentioned",
  "destination": "complete destination address in English with ALL details (house number, area, city)",
  "original_text": "the exact text you heard from the audio"
}

Example:
If audio says "مجھے مکان نمبر چار جوہر ٹاؤن لاہور میں جانا ہے"
Response should be:
{
  "source": null,
  "destination": "House Number 4, Johar Town, Lahore",
  "original_text": "مجھے مکان نمبر چار جوہر ٹاؤن لاہور میں جانا ہے"
}`;

      const response = await this.client.models.generateContent({
        model: "gemini-2.5-flash",
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt },
              {
                inlineData: {
                  data: audioBase64,
                  mimeType: mimeType
                }
              }
            ]
          }
        ]
      });

      const responseText = response.text.trim();

      // Clean the response (remove markdown code blocks if present)
      let cleanedResponse = responseText
        .replace(/```json\n?/g, "")
        .replace(/```\n?/g, "")
        .trim();

      // Parse JSON response
      const locationData = JSON.parse(cleanedResponse);

      // Return source, destination, and original text
      const result = {
        source: locationData.source,
        destination: locationData.destination,
        original_text: locationData.original_text || "Audio processed"
      };

      logger.info(
        `Locations extracted from audio - Source: ${result.source}, Destination: ${result.destination}`
      );

      // Clean up the audio file
      this.cleanupFile(audioFilePath);

      return result;
    } catch (error) {
      logger.error(`Gemini audio processing error: ${error.message}`);
      // Clean up file even on error
      this.cleanupFile(audioFilePath);
      throw new Error(`Failed to process audio: ${error.message}`);
    }
  }

  /**
   * Get MIME type from file path
   * @param {string} filePath - File path
   * @returns {string} MIME type
   */
  getMimeType(filePath) {
    const extension = filePath.split(".").pop().toLowerCase();
    const mimeTypes = {
      mp3: "audio/mp3",
      wav: "audio/wav",
      m4a: "audio/mp4",
      aac: "audio/aac",
      ogg: "audio/ogg",
      flac: "audio/flac",
      webm: "audio/webm"
    };
    return mimeTypes[extension] || "audio/mpeg";
  }

  /**
   * Clean up uploaded file
   * @param {string} filePath - Path to file
   */
  cleanupFile(filePath) {
    try {
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        logger.info(`Cleaned up file: ${filePath}`);
      }
    } catch (error) {
      logger.error(`Error cleaning up file ${filePath}: ${error.message}`);
    }
  }

  /**
   * Translate text to English
   * @param {string} text - Text to translate
   * @returns {Promise<string>} Translated text
   */
  async translateToEnglish(text) {
    if (!this.isAvailable()) {
      throw new Error("Gemini API key is not configured");
    }

    try {
      const prompt = `Translate the following text to English. Only output the translation, no explanations:

"${text}"`;

      const response = await this.client.models.generateContent({
        model: "gemini-2.5-flash",
        contents: prompt
      });

      return response.text.trim();
    } catch (error) {
      logger.error(`Gemini translation error: ${error.message}`);
      throw error;
    }
  }
}

export default new GeminiService();
