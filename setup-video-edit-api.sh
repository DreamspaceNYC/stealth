#!/bin/bash

# 📁 Create backend folder
mkdir -p ~/StealthEditAPI && cd ~/StealthEditAPI

# 📦 Init Node project
npm init -y

# 📚 Install dependencies
npm install express multer fluent-ffmpeg exiftool-vendored crypto dotenv cors

# 📝 Create .env file
echo "PORT=5000" > .env

# 📝 Create server.js file
cat << 'JS' > server.js
const express = require('express');
const multer = require('multer');
const ffmpeg = require('fluent-ffmpeg');
const { exiftool } = require('exiftool-vendored');
const fs = require('fs');
const crypto = require('crypto');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const upload = multer({ dest: 'uploads/' });
app.use(cors());

app.post('/process-video', upload.single('video'), async (req, res) => {
  try {
    const filePath = req.file.path;
    const outPath = \`outputs/\${Date.now()}-edited.mp4\`;
    const hash = crypto.createHash('sha1').update(fs.readFileSync(filePath)).digest('hex');

    // FFmpeg: crop, compress
    await new Promise((resolve, reject) => {
      ffmpeg(filePath)
        .videoFilters('scale=720:1280')
        .outputOptions('-preset veryfast')
        .save(outPath)
        .on('end', resolve)
        .on('error', reject);
    });

    // Metadata spoofing
    await exiftool.write(outPath, {
      Artist: 'StealthAI',
      GPSLatitude: '48.8566',
      GPSLongitude: '2.3522'
    });

    const spoofedHash = hash.slice(0, 16) + Math.random().toString(36).substring(2, 10);

    res.json({
      status: 'success',
      editedFile: outPath,
      spoofedHash,
      downloadUrl: \`http://localhost:\${process.env.PORT}/\${outPath}\`
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: 'error', message: err.message });
  }
});

app.use('/outputs', express.static(path.join(__dirname, 'outputs')));

// 📂 Ensure outputs dir exists
if (!fs.existsSync('outputs')) fs.mkdirSync('outputs');

const port = process.env.PORT || 5000;
app.listen(port, () => console.log(\`🚀 Server running on port \${port}\`));
JS

# ✅ All set
echo "\n🎉 StealthEditAPI is ready. Run it using:"
echo "node server.js"
