const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");
const path = require("path");

admin.initializeApp();

/**
 * Cloud Function: Analyze food image using Google Generative AI
 *
 * Request body:
 * {
 *   "imageBase64": "string (base64 encoded image)"
 * }
 *
 * Response:
 * {
 *   "label": "string",
 *   "calories": number,
 *   "protein": number,
 *   "fat": number,
 *   "carbs": number,
 *   "fiber": number
 * }
 */
exports.analyzeFood = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type,Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    // Verify Firebase ID token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const idToken = authHeader.substring(7);
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    const { imageBase64 } = req.body;
    if (!imageBase64) {
      return res.status(400).json({ error: "Missing imageBase64" });
    }

    // Call Google Generative AI API
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: "API key not configured" });
    }

    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        contents: [
          {
            parts: [
              {
                text: `Analyze this food image and extract nutritional information per 100g. 
                      Return a JSON object with these exact keys:
                      - label: name of the food (string)
                      - calories: calories per 100g (number, default 0)
                      - protein: protein in grams per 100g (number, default 0)
                      - fat: fat in grams per 100g (number, default 0)
                      - carbs: carbohydrates in grams per 100g (number, default 0)
                      - fiber: fiber in grams per 100g (number, default 0)
                      
                      Return ONLY the JSON object, no other text.`,
              },
              {
                inlineData: {
                  mimeType: "image/jpeg",
                  data: imageBase64,
                },
              },
            ],
          },
        ],
      },
    );

    const content = response.data.candidates[0].content.parts[0].text;

    // Parse JSON response
    let nutrients;
    try {
      nutrients = JSON.parse(content);
    } catch (e) {
      // Try to extract JSON from response if it contains extra text
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        nutrients = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("Could not parse nutrition data");
      }
    }

    // Validate and provide defaults
    nutrients = {
      label: nutrients.label || "Unknown Food",
      calories: nutrients.calories || 0,
      protein: nutrients.protein || 0,
      fat: nutrients.fat || 0,
      carbs: nutrients.carbs || 0,
      fiber: nutrients.fiber || 0,
    };

    // Log for monitoring
    console.log(`User ${userId} analyzed food: ${nutrients.label}`);

    res.json(nutrients);
  } catch (error) {
    console.error("Error analyzing food:", error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Cloud Function: Get barcode data from Open Food Facts
 *
 * Request body:
 * {
 *   "barcode": "string (EAN/UPC barcode)"
 * }
 *
 * Response:
 * {
 *   "label": "string",
 *   "calories": number,
 *   "protein": number,
 *   "fat": number,
 *   "carbs": number,
 *   "fiber": number
 * }
 */
exports.getBarcodeData = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type,Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    // Verify Firebase ID token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const idToken = authHeader.substring(7);
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    const { barcode } = req.body;
    if (!barcode) {
      return res.status(400).json({ error: "Missing barcode" });
    }

    // Call Open Food Facts API (free, no authentication needed)
    const response = await axios.get(
      `https://world.openfoodfacts.org/api/v0/product/${barcode}.json`,
    );

    if (response.data.status === 0) {
      return res.status(404).json({ error: "Product not found" });
    }

    const product = response.data.product;

    // Extract nutrition info
    const nutrients = {
      label: product.product_name || "Unknown Product",
      calories: product.nutriments?.["energy-kcal_100g"] || 0,
      protein: product.nutriments?.protein_100g || 0,
      fat: product.nutriments?.fat_100g || 0,
      carbs: product.nutriments?.carbohydrates_100g || 0,
      fiber: product.nutriments?.fiber_100g || 0,
    };

    // Log for monitoring
    console.log(
      `User ${userId} scanned barcode: ${barcode} -> ${nutrients.label}`,
    );

    res.json(nutrients);
  } catch (error) {
    console.error("Error getting barcode data:", error);
    res.status(500).json({ error: error.message });
  }
});
