const { RekognitionClient, DetectLabelsCommand } = require("@aws-sdk/client-rekognition");
const { DynamoDBClient, PutItemCommand, ScanCommand } = require("@aws-sdk/client-dynamodb");
const { randomUUID } = require("crypto");
const https = require("https");

const rekognition = new RekognitionClient({ region: "us-east-1" });
const dynamodb = new DynamoDBClient({ region: "us-east-1" });
const GROQ_API_KEY = "YOUR_GROQ_API_KEY_HERE";

const SUPPORTED_LANGUAGES = [
  "Hindi", "Marathi", "Tamil", "Telugu", "Bengali",
  "Gujarati", "Kannada", "Malayalam", "Punjabi", "Urdu"
];

const CRAFTS = {
  "Warli Painting": {
    region: "Palghar district, Maharashtra",
    history: "Ancient tribal art form over 2500 years old by the Warli tribe",
    technique: "White rice paste pigment on dark mud/brown background using geometric shapes — circles, triangles, squares",
    gi_tag: false,
    occasions: "Harvest festivals, weddings, storytelling, home decor",
    price_range: "₹300 - ₹30,000"
  },
  "Madhubani Painting": {
    region: "Mithila region, Bihar",
    history: "Originated during the time of Ramayana, practiced by women of Mithila for centuries",
    technique: "Natural dyes on handmade paper with intricate line work, floral borders, and human/deity figures",
    gi_tag: true,
    occasions: "Weddings, festivals, home decoration",
    price_range: "₹500 - ₹50,000"
  },
  "Gond Painting": {
    region: "Madhya Pradesh / Chhattisgarh",
    history: "Ancient tribal art of the Gond community, one of India's largest tribes",
    technique: "Intricate dots and dashes forming vibrant animals, trees and nature scenes",
    gi_tag: false,
    occasions: "Home decor, art collection, cultural gifting",
    price_range: "₹500 - ₹30,000"
  },
  "Banarasi Silk Saree": {
    region: "Varanasi, Uttar Pradesh",
    history: "Dating back to the Mughal era, 14th century. Woven by the Ansari Muslim weaver community.",
    technique: "Intricate zari (gold/silver thread) brocade weaving on pure silk",
    gi_tag: true,
    occasions: "Weddings, festivals, religious ceremonies",
    price_range: "₹5,000 - ₹2,00,000"
  },
  "Kanjivaram Silk Saree": {
    region: "Kanchipuram, Tamil Nadu",
    history: "Over 400 years old, woven by the Devangas and Saliyas communities of Tamil Nadu",
    technique: "Pure mulberry silk with bold contrast borders, interlocked weaving technique",
    gi_tag: true,
    occasions: "Weddings, temple visits, classical dance performances",
    price_range: "₹8,000 - ₹3,00,000"
  },
  "Ganesha Idol": {
    region: "Pan-India (Pune, Jaipur, Tamil Nadu specialties)",
    history: "Ganesha idol-making is a centuries-old craft, central to Ganesh Chaturthi celebrations",
    technique: "Shadu clay, POP, or eco-friendly clay sculpted and painted by hand",
    gi_tag: false,
    occasions: "Ganesh Chaturthi, home temples, gifting",
    price_range: "₹100 - ₹1,00,000"
  },
  "Terracotta Pottery": {
    region: "Bankura, West Bengal / Rajasthan / Tamil Nadu",
    history: "One of the oldest art forms in India, dating back to the Indus Valley Civilization",
    technique: "Hand-molded or wheel-thrown red clay, sun-dried and kiln-fired, sometimes painted",
    gi_tag: false,
    occasions: "Home decor, religious ceremonies, daily use",
    price_range: "₹100 - ₹5,000"
  },
  "Kolhapuri Chappals": {
    region: "Kolhapur, Maharashtra",
    history: "Over 800 years old, traditionally made by the Chamar artisan community of Kolhapur",
    technique: "Vegetable-tanned leather, hand-stitched with brass nail work and intricate cutwork",
    gi_tag: true,
    occasions: "Daily wear, ethnic outfits, casual fashion",
    price_range: "₹500 - ₹3,000"
  }
};

// ─────────────────────────────────────────────────────────
// GROQ GENERIC CALLER
// ─────────────────────────────────────────────────────────
function callGroq(messages, maxTokens = 1500, temperature = 0.7) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      messages,
      temperature,
      max_tokens: maxTokens
    });

    const options = {
      hostname: "api.groq.com",
      path: "/openai/v1/chat/completions",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Length": Buffer.byteLength(body)
      }
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error("Failed to parse Groq response")); }
      });
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

// ─────────────────────────────────────────────────────────
// STEP 1 — GROQ VISION: CLASSIFY THE CRAFT
// ─────────────────────────────────────────────────────────
async function classifyWithVision(imageBase64) {
  const classifyPrompt = `You are an expert in Indian handicrafts and folk art with 30 years of experience.

Carefully examine this image and identify if it belongs to ONE of these 8 specific Indian handicrafts:

1. Warli Painting — monochrome white figures on dark brown/mud background, geometric tribal art from Maharashtra
2. Madhubani Painting — colorful Bihar folk art with floral borders, fish motifs, deity/human figures, intricate line work
3. Gond Painting — vibrant tribal art from MP/Chhattisgarh with dot & dash patterns filling animals, peacocks, trees
4. Banarasi Silk Saree — heavy silk saree with gold/silver zari brocade weaving from Varanasi
5. Kanjivaram Silk Saree — pure mulberry silk saree with bold contrast borders from Kanchipuram Tamil Nadu
6. Ganesha Idol — handmade clay or POP sculpture of Lord Ganesha (elephant head deity)
7. Terracotta Pottery — red/brown clay handmade pots, vases or vessels, kiln-fired earthenware
8. Kolhapuri Chappals — handmade vegetable-tanned leather sandals/footwear from Kolhapur Maharashtra

Rules:
- If the image clearly matches one of the 8, set matched: true
- If it is a handmade/artisan product but NOT one of the 8, set matched: false and is_artisan: true
- If it is not a handmade product at all (food, vehicle, landscape, phone etc.), set matched: false and is_artisan: false
- Be confident — do not default to unmatched if you can see a clear visual match

Respond with ONLY valid JSON, no extra text:
{
  "matched": true or false,
  "craft_name": "<exact name from list above, or null>",
  "is_artisan": true or false,
  "confidence": "high", "medium", or "low"
}`;

  const groqData = await callGroq([
    {
      role: "user",
      content: [
        { type: "text", text: classifyPrompt },
        {
          type: "image_url",
          image_url: { url: `data:image/jpeg;base64,${imageBase64}` }
        }
      ]
    }
  ], 200, 0.1); // Low temperature for deterministic classification

  if (!groqData.choices?.length) throw new Error("Vision classification failed");
  const raw = groqData.choices[0].message.content.trim();
  const match = raw.match(/\{[\s\S]*\}/);
  if (!match) throw new Error("No JSON in vision response");
  return JSON.parse(match[0]);
}

// ─────────────────────────────────────────────────────────
// STEP 2 — GROQ TEXT: GENERATE CAPTIONS
// ─────────────────────────────────────────────────────────
async function generateCaptions(craftName, craftData, selectedLanguage) {
  const prompt = `You are an expert in Indian handmade artisan products and social media marketing.

CONFIRMED CRAFT: ${craftName}
Region: ${craftData.region}
History: ${craftData.history}
Technique: ${craftData.technique}
GI Tag: ${craftData.gi_tag ? "Yes — Geographical Indication certified" : "No"}
Occasions: ${craftData.occasions}
Price Range: ${craftData.price_range}

IMPORTANT: Product name is LOCKED as "${craftName}". Do NOT change it.
Generate captions in English and ${selectedLanguage}.

Respond with ONLY this JSON:
{
  "english": "<2-3 sentence emotional Instagram caption with cultural context and heritage. Add 1-2 relevant emojis.>",
  "local_caption": "<Natural ${selectedLanguage} caption — NOT Google Translate. Use native expressions. Add 1-2 emojis.>",
  "hashtags": ["#VocalForLocal", "#ArtisanIndia", "#MadeInIndia", "<9 more specific hashtags>"],
  "whatsapp_link": "https://wa.me/?text=<URL encoded: craft name + space + english caption + space + top 5 hashtags>"
}`;

  const groqData = await callGroq([
    {
      role: "system",
      content: "You are an expert in Indian handmade artisan products and social media marketing. Always respond with valid JSON only. No explanation, no markdown, no extra text."
    },
    { role: "user", content: prompt }
  ], 1500, 0.7);

  if (!groqData.choices?.length) throw new Error("Caption generation failed");
  const raw = groqData.choices[0].message.content.trim();
  const match = raw.match(/\{[\s\S]*\}/);
  if (!match) throw new Error("No JSON in caption response");
  return JSON.parse(match[0]);
}

// ─────────────────────────────────────────────────────────
// MAIN HANDLER
// ─────────────────────────────────────────────────────────
exports.handler = async (event) => {
  const path = event.path || event.rawPath || "/dev/generate";

  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST,GET,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type"
      },
      body: ""
    };
  }

  // ── TRENDING ──
  if (path.includes("/trending")) {
    try {
      const result = await dynamodb.send(new ScanCommand({ TableName: "ArtisanContent" }));
      const items = result.Items || [];
      const productCount = {}, hashtagCount = {}, languageCount = {}, dailyScans = {};
      items.forEach(item => {
        const product = item.product_type?.S || "Unknown";
        productCount[product] = (productCount[product] || 0) + 1;
        (item.hashtags?.S || "").split(" ").forEach(tag => {
          if (tag.startsWith("#")) hashtagCount[tag] = (hashtagCount[tag] || 0) + 1;
        });
        const lang = item.local_language?.S || "Hindi";
        languageCount[lang] = (languageCount[lang] || 0) + 1;
        const date = (item.timestamp?.S || "").substring(0, 10);
        if (date) dailyScans[date] = (dailyScans[date] || 0) + 1;
      });
      return {
        statusCode: 200,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({
          total_scans: items.length,
          top_products: Object.entries(productCount).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([name, count]) => ({ name, count })),
          top_hashtags: Object.entries(hashtagCount).sort((a, b) => b[1] - a[1]).slice(0, 10).map(([tag, count]) => ({ tag, count })),
          top_languages: Object.entries(languageCount).sort((a, b) => b[1] - a[1]).map(([language, count]) => ({ language, count })),
          daily_scans: Object.entries(dailyScans).sort((a, b) => a[0].localeCompare(b[0])).slice(-7).map(([date, count]) => ({ date, count }))
        })
      };
    } catch (err) {
      return { statusCode: 500, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: err.message }) };
    }
  }

  // ── HISTORY ──
  if (path.includes("/history")) {
    try {
      const result = await dynamodb.send(new ScanCommand({ TableName: "ArtisanContent", Limit: 20 }));
      const items = (result.Items || []).map(item => ({
        id: item.id?.S || "",
        product_type: item.product_type?.S || "Unknown",
        labels: item.labels?.S || "",
        english: item.english?.S || "",
        local_caption: item.local_caption?.S || "",
        hashtags: item.hashtags?.S || "",
        timestamp: item.timestamp?.S || ""
      })).sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
      return { statusCode: 200, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ items }) };
    } catch (err) {
      return { statusCode: 500, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: err.message }) };
    }
  }

  // ── GENERATE ──
  try {
    let imageBase64, selectedLanguage;
    try {
      const body = typeof event.body === "string" ? JSON.parse(event.body) : (event.body || {});
      imageBase64 = body.image;
      selectedLanguage = body.language || "Hindi";
    } catch {
      return { statusCode: 400, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: "Invalid request body" }) };
    }

    if (!imageBase64) return { statusCode: 400, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: "No image provided" }) };
    if (!SUPPORTED_LANGUAGES.includes(selectedLanguage)) selectedLanguage = "Hindi";

    // ── STEP 1: Rekognition (cosmetic labels only) ──
    let labels = [];
    try {
      const rekResult = await rekognition.send(new DetectLabelsCommand({
        Image: { Bytes: Buffer.from(imageBase64, "base64") },
        MaxLabels: 10,
        MinConfidence: 70
      }));
      labels = rekResult.Labels.map(l => l.Name);
      console.log("Rekognition labels (cosmetic):", labels);
    } catch (e) {
      console.log("Rekognition failed, continuing without labels:", e.message);
      // Non-fatal — labels are cosmetic only now
    }

    // ── STEP 2: Groq Vision — classify the craft ──
    let visionResult;
    try {
      visionResult = await classifyWithVision(imageBase64);
      console.log("Vision classification:", JSON.stringify(visionResult));
    } catch (e) {
      return { statusCode: 500, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: "Image classification failed: " + e.message }) };
    }

    // ── STEP 3: Handle rejections ──
    if (!visionResult.matched) {
      if (!visionResult.is_artisan) {
        // Not a handmade product at all
        return {
          statusCode: 200,
          headers: { "Access-Control-Allow-Origin": "*" },
          body: JSON.stringify({
            is_artisan: false,
            rejection_type: "not_artisan",
            message_en: "This does not appear to be a handmade product image. Please provide a valid image of a handcrafted artisan product. 🙏",
            message_local: "यह एक हस्तनिर्मित उत्पाद की तस्वीर नहीं लगती। कृपया किसी हस्तशिल्प उत्पाद की वैध तस्वीर प्रदान करें। 🙏",
            local_language: selectedLanguage,
            labels
          })
        };
      }
      // Handmade but not in our 8
      return {
        statusCode: 200,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({
          is_artisan: true,
          rejection_type: "coming_soon",
          message_en: "✨ This looks like a beautiful handmade product! This craft will be supported in a future update of ArtisanAI Boost. Stay tuned! 🚀",
          message_local: "✨ यह एक सुंदर हस्तनिर्मित उत्पाद लगता है! यह शिल्प ArtisanAI Boost के भविष्य के अपडेट में शामिल किया जाएगा। जुड़े रहें! 🚀",
          local_language: selectedLanguage,
          labels
        })
      };
    }

    // ── STEP 4: Get craft data ──
    const craftName = visionResult.craft_name;
    const craftData = CRAFTS[craftName];

    if (!craftData) {
      // Vision returned a name not in our map — treat as coming_soon
      return {
        statusCode: 200,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({
          is_artisan: true,
          rejection_type: "coming_soon",
          message_en: "✨ This looks like a beautiful handmade product! This craft will be supported in a future update of ArtisanAI Boost. Stay tuned! 🚀",
          message_local: "✨ यह एक सुंदर हस्तनिर्मित उत्पाद लगता है! यह शिल्प ArtisanAI Boost के भविष्य के अपडेट में शामिल किया जाएगा। जुड़े रहें! 🚀",
          local_language: selectedLanguage,
          labels
        })
      };
    }

    // ── STEP 5: Generate captions ──
    let aiResponse;
    try {
      aiResponse = await generateCaptions(craftName, craftData, selectedLanguage);
    } catch (e) {
      return { statusCode: 500, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: "Caption generation failed: " + e.message }) };
    }

    const content = {
      is_artisan: true,
      rejection_type: null,
      product_type: craftName,
      english: aiResponse.english,
      local_language: selectedLanguage,
      local_caption: aiResponse.local_caption,
      hashtags: aiResponse.hashtags,
      whatsapp_link: aiResponse.whatsapp_link || "",
      labels,
      craft_region: craftData.region,
      gi_tag: craftData.gi_tag
    };

    // ── STEP 6: DynamoDB ──
    await dynamodb.send(new PutItemCommand({
      TableName: "ArtisanContent",
      Item: {
        id: { S: randomUUID() },
        labels: { S: labels.join(", ") },
        product_type: { S: content.product_type },
        english: { S: content.english },
        local_language: { S: selectedLanguage },
        local_caption: { S: content.local_caption },
        hashtags: { S: content.hashtags.join(" ") },
        whatsapp_link: { S: content.whatsapp_link },
        craft_region: { S: content.craft_region },
        gi_tag: { BOOL: content.gi_tag },
        timestamp: { S: new Date().toISOString() }
      }
    }));

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify(content)
    };

  } catch (err) {
    console.error("Handler error:", err);
    return { statusCode: 500, headers: { "Access-Control-Allow-Origin": "*" }, body: JSON.stringify({ error: err.message }) };
  }
};
