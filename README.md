
# 🪴 ArtisanAI Boost
### Empowering Indian Artisans with AI-Powered Marketing

> Built for **AWS AI for Bharat Hackathon 2026** | Track: AI for Communities, Access & Public Impact

---

## 📱 Download App
[⬇️ Download APK](https://drive.google.com/file/d/1U0GQrePMXLjZub5WfPrqm-NboKzGdCEj/view?usp=sharing)

---

## 🧩 Problem Statement

India has over 7 million rural artisans crafting world-class handmade products — Warli paintings, Banarasi sarees, Kolhapuri chappals, and more. Yet most of them:

- Cannot write marketing content in English
- Have no access to graphic designers or social media managers
- Struggle to sell online despite having exceptional products

**Result:** Beautiful, GI-tagged crafts go unnoticed while artisans earn far below their potential.

---

## 💡 Our Solution

**ArtisanAI Boost** is a Flutter mobile app that lets an artisan simply **scan or photograph their product** and instantly receive:

- ✅ AI-identified craft name and cultural heritage story
- ✅ Professional Instagram captions in **English + regional language**
- ✅ 12 smart hashtags for maximum reach
- ✅ Ready-to-send WhatsApp share link
- ✅ GI Tag certification badge (where applicable)
- ✅ Downloadable marketing content as a text file

---

## 🏺 Supported Crafts (8 Categories)

| Craft | Region | GI Tag |
|---|---|---|
| 🖼️ Warli Painting | Palghar, Maharashtra | ❌ |
| 🎨 Madhubani Painting | Mithila, Bihar | ✅ |
| 🦚 Gond Painting | Madhya Pradesh & Chhattisgarh | ❌ |
| 🥻 Banarasi Silk Saree | Varanasi, Uttar Pradesh | ✅ |
| 🥻 Kanjivaram Silk Saree | Kanchipuram, Tamil Nadu | ✅ |
| 🐘 Ganesha Idol | Pan-India | ❌ |
| 🏺 Terracotta Pottery | Bankura, West Bengal | ❌ |
| 👡 Kolhapuri Chappals | Kolhapur, Maharashtra | ✅ |

---

## 🌐 Supported Languages

Hindi 🇮🇳 | Marathi | Tamil | Telugu | Bengali | Gujarati | Kannada | Malayalam | Punjabi | Urdu

---

## 🏗️ Architecture



| Step | Service | Role |
|---|---|---|
| 1️⃣ | 📱 Flutter App | Captures image, selects language, sends Base64 to API |
| 2️⃣ | 🔗 AWS API Gateway | Receives request, routes to Lambda |
| 3️⃣ | ⚡ AWS Lambda | Core backend logic, orchestrates all services |
| 4️⃣ | 👁️ AWS Rekognition | Detects up to 25 visual labels from the image |
| 5️⃣ | 🧠 Custom Matching Engine | Weighted scoring + disqualification + tiebreak logic |
| 6️⃣ | 🤖 Groq AI (Llama 3.3-70b) | Generates culturally rich captions in selected language |
| 7️⃣ | 🗄️ AWS DynamoDB | Stores scan history, analytics, trending data |
| 8️⃣ | 📲 App Response | Returns captions, hashtags, GI tag, WhatsApp link |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) — Android |
| **Authentication** | AWS Amplify (Cognito) |
| **AI Vision** | AWS Rekognition |
| **Caption Generation** | Groq AI — Llama 3.3-70b-versatile |
| **Backend** | AWS Lambda (Node.js) |
| **API** | AWS API Gateway |
| **Database** | AWS DynamoDB |

---

## 📂 Project Structure

```
artisanai-boost/
├── lib/
│   ├── main.dart                 # Core app, home screen, scan logic
│   ├── auth_service.dart         # AWS Cognito authentication
│   ├── login_screen.dart         # Login UI
│   ├── signup_screen.dart        # Signup UI
│   ├── history_screen.dart       # Scan history
│   ├── analytics_screen.dart     # Trending analytics dashboard
│   └── subscription_screen.dart  # Free / Pro / Premium plans
└── backend/
    └── lambda_function.js        # AWS Lambda handler
```


 "amplifyconfiguration.dart" is excluded for security (contains AWS Cognito credentials).

---

## 💎 Subscription Tiers

| Plan | Daily Scans | Regional Captions | Hashtags |
|---|---|---|---|
| **FREE** | 5 | ❌ | 5 only |
| **PRO** | 50 | ✅ | All 12 |
| **PREMIUM** | Unlimited | ✅ | All 12 |

---

## 🤖 How the AI Matching Works

The Lambda function uses a **custom weighted scoring engine**:

1. **AWS Rekognition** detects up to 25 visual labels from the image
2. Each label is matched against craft-specific weighted keyword lists
3. **Disqualification rules** eliminate false matches
4. **Tiebreak logic** resolves close scores between similar crafts
5. If no craft is matched but image is handmade → "Coming Soon" response
6. If image is not a handmade product at all → rejection with guidance

---

## 🚀 Running Locally

### Prerequisites
- Flutter SDK installed
- AWS account with Rekognition, Lambda, DynamoDB, API Gateway configured
- Groq API key

### Steps

bash
# Clone the repo
git clone https://github.com/AmeyaSawant007/ArtisanAI_Boost.git
cd ArtisanAI_Boost

# Install Flutter dependencies
flutter pub get

# Add your own amplifyconfiguration.dart
(Configure AWS Amplify with your Cognito details)

# Update API URL in main.dart
 static const String apiUrl = "YOUR_API_GATEWAY_URL";

# Run the app
flutter run

---

### Lambda Setup
1. Create a Lambda function in `us-east-1`
2. Paste `lambda_function.js` code
3. Set environment variable: `GROQ_API_KEY=your_key_here`
4. Attach IAM roles for Rekognition and DynamoDB access
5. Create API Gateway trigger with `/dev/generate`, `/dev/trending`, `/dev/history` routes

---

## 👥 Team

**Team Leader:** Ameya V. Sawant

**Team Members:**
Ameya Sawant, 
Siddhesh Mohite, 
Jatin Takke, 
Yash Kate

**Hackathon:** AWS AI for Bharat 2026
**Track:** AI for Media, Content & Digital Experiences

---

## 📄 License

This project was built for hackathon purposes. All rights reserved © 2026 ArtisanAI Boost Team.
```
