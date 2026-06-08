const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// Constants
const TIMEOUT_MS = 25000; // 25 seconds
const MAX_IMAGE_SIZE = 5000000; // 5MB base64
const MAX_BARCODE_LENGTH = 14;

/**
 * Cloud Function: Analyze food image using Google Generative AI
 * 
 * Security:
 * - Validates Firebase ID token
 * - Restricts to authenticated users only
 * - Returns generic error messages
 * 
 * Request body:
 * {
 *   "imageBase64": "string (base64 encoded image, max 5MB)"
 * }
 * 
 * Response (root-level, not nested):
 * {
 *   "label": "string",
 *   "calories": number,
 *   "protein": number,
 *   "fat": number,
 *   "carbs": number,
 *   "fiber": number
 * }
 */
exports.analyzeFood = functions
  .runWith({ timeoutSeconds: 30, memory: '512MB' })
  .https.onRequest(async (req, res) => {
    // CORS: Only allow Firebase auth, not public origin
    res.set('Access-Control-Allow-Origin', 'https://kalorientracker-3390e.firebaseapp.com');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type,Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      // Verify Firebase ID token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized: Missing or invalid token' });
      }

      let decodedToken;
      try {
        const idToken = authHeader.substring(7);
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
      }

      const userId = decodedToken.uid;
      const { imageBase64 } = req.body;

      // Validate input
      if (!imageBase64) {
        return res.status(400).json({ error: 'Missing imageBase64 in request body' });
      }

      if (typeof imageBase64 !== 'string') {
        return res.status(400).json({ error: 'imageBase64 must be a string' });
      }

      if (imageBase64.length > MAX_IMAGE_SIZE) {
        return res.status(413).json({ error: 'Image too large' });
      }

      // Get Gemini API key from Secret Manager
      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        console.error('GEMINI_API_KEY not configured');
        return res.status(500).json({ error: 'Service configuration error' });
      }

      // Call Google Generative AI API with timeout
      let response;
      try {
        response = await axios.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
          {
            contents: [
              {
                parts: [
                  {
                    text: `Analyze this food image and extract nutritional information per 100g. 
                          Return ONLY a valid JSON object (no markdown, no code blocks) with these exact keys:
                          - label: name of the food (string, max 100 chars)
                          - calories: calories per 100g (number, 0-1000, default 0)
                          - protein: protein in grams per 100g (number, 0-100, default 0)
                          - fat: fat in grams per 100g (number, 0-100, default 0)
                          - carbs: carbohydrates in grams per 100g (number, 0-100, default 0)
                          - fiber: fiber in grams per 100g (number, 0-100, default 0)
                          
                          Example response:
                          {"label": "Pizza Margherita", "calories": 266, "protein": 11, "fat": 10, "carbs": 33, "fiber": 2.5}`,
                  },
                  {
                    inlineData: {
                      mimeType: 'image/jpeg',
                      data: imageBase64,
                    },
                  },
                ],
              },
            ],
          },
          {
            params: { key: apiKey },
            timeout: TIMEOUT_MS,
          }
        );
      } catch (error) {
        if (error.code === 'ECONNABORTED') {
          console.warn(`Image analysis timeout for user ${userId}`);
          return res.status(504).json({ error: 'Service timeout' });
        }
        console.error(`Gemini API error for user ${userId}:`, error.message);
        return res.status(502).json({ error: 'External service error' });
      }

      // Parse Gemini response
      if (!response.data?.candidates?.[0]?.content?.parts?.[0]?.text) {
        console.error(`Invalid Gemini response for user ${userId}`);
        return res.status(502).json({ error: 'Invalid response from AI service' });
      }

      const content = response.data.candidates[0].content.parts[0].text;

      // Parse JSON response
      let nutrients;
      try {
        // Try direct parse first
        nutrients = JSON.parse(content);
      } catch (e) {
        // Try to extract JSON from response if it contains markdown code blocks
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          try {
            nutrients = JSON.parse(jsonMatch[0]);
          } catch (e2) {
            console.error(`Failed to parse nutrition JSON for user ${userId}`);
            return res.status(502).json({ error: 'Failed to parse AI response' });
          }
        } else {
          return res.status(502).json({ error: 'Invalid response format' });
        }
      }

      // Validate and sanitize response
      nutrients = {
        label: String(nutrients.label || 'Unknown Food').substring(0, 100),
        calories: Math.max(0, Math.min(1000, Number(nutrients.calories) || 0)),
        protein: Math.max(0, Math.min(100, Number(nutrients.protein) || 0)),
        fat: Math.max(0, Math.min(100, Number(nutrients.fat) || 0)),
        carbs: Math.max(0, Math.min(100, Number(nutrients.carbs) || 0)),
        fiber: Math.max(0, Math.min(100, Number(nutrients.fiber) || 0)),
      };

      // Log for monitoring (without sensitive user data in production)
      console.log(`Image analysis: ${nutrients.label} (${nutrients.calories} kcal)`);

      // Return root-level nutrients object (NOT nested under 'nutrients' key)
      res.json(nutrients);
    } catch (error) {
      console.error('Unexpected error in analyzeFood:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

/**
 * Cloud Function: Get barcode data from Open Food Facts
 * 
 * Security:
 * - Validates Firebase ID token
 * - Input validation on barcode
 * - Generic error messages
 * 
 * Request body:
 * {
 *   "barcode": "string (EAN/UPC barcode, 8-14 digits)"
 * }
 * 
 * Response (root-level):
 * {
 *   "label": "string",
 *   "calories": number,
 *   "protein": number,
 *   "fat": number,
 *   "carbs": number,
 *   "fiber": number
 * }
 */
exports.getBarcodeData = functions
  .runWith({ timeoutSeconds: 20, memory: '256MB' })
  .https.onRequest(async (req, res) => {
    // CORS: Only allow Firebase auth
    res.set('Access-Control-Allow-Origin', 'https://kalorientracker-3390e.firebaseapp.com');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type,Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      // Verify Firebase ID token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      let decodedToken;
      try {
        const idToken = authHeader.substring(7);
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const userId = decodedToken.uid;
      const { barcode } = req.body;

      // Validate input
      if (!barcode) {
        return res.status(400).json({ error: 'Missing barcode in request body' });
      }

      const barcodeStr = String(barcode).replace(/\s/g, '');
      if (!/^\d+$/.test(barcodeStr)) {
        return res.status(400).json({ error: 'Invalid barcode format' });
      }

      if (barcodeStr.length < 8 || barcodeStr.length > MAX_BARCODE_LENGTH) {
        return res.status(400).json({ error: 'Invalid barcode length' });
      }

      // Call Open Food Facts API with timeout
      let response;
      try {
        response = await axios.get(
          `https://world.openfoodfacts.org/api/v0/product/${barcodeStr}.json`,
          { timeout: TIMEOUT_MS }
        );
      } catch (error) {
        if (error.code === 'ECONNABORTED') {
          console.warn(`Barcode lookup timeout for barcode ${barcodeStr}`);
          return res.status(504).json({ error: 'Service timeout' });
        }
        console.error(`OpenFoodFacts API error: ${error.message}`);
        return res.status(502).json({ error: 'External service error' });
      }

      // Check if product found
      if (response.data?.status === 0) {
        console.log(`Product not found for barcode: ${barcodeStr}`);
        return res.status(404).json({ error: 'Product not found' });
      }

      const product = response.data?.product;
      if (!product) {
        return res.status(502).json({ error: 'Invalid response from product database' });
      }

      // Extract and validate nutrition info
      const nutrients = {
        label: String(product.product_name || 'Unknown Product').substring(0, 100),
        calories: Math.max(0, Math.min(1000, Number(product.nutriments?.['energy-kcal_100g']) || 0)),
        protein: Math.max(0, Math.min(100, Number(product.nutriments?.protein_100g) || 0)),
        fat: Math.max(0, Math.min(100, Number(product.nutriments?.fat_100g) || 0)),
        carbs: Math.max(0, Math.min(100, Number(product.nutriments?.carbohydrates_100g) || 0)),
        fiber: Math.max(0, Math.min(100, Number(product.nutriments?.fiber_100g) || 0)),
      };

      console.log(`Barcode lookup: ${barcodeStr} -> ${nutrients.label}`);

      // Return root-level nutrients object
      res.json(nutrients);
    } catch (error) {
      console.error('Unexpected error in getBarcodeData:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
