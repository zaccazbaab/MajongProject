const fetch = require("node-fetch");

const ROBOFLOW_API_KEY = process.env.ROBOFLOW_API_KEY;

module.exports = async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({ error: "只接受 POST" });

  const { imageBase64 } = req.body;
  if (!imageBase64) return res.status(400).json({ error: "請提供 imageBase64" });

  try {
    const response = await fetch(
      "https://serverless.roboflow.com/infer/workflows/mahjong-cd5im/mahjongriichi",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          api_key: ROBOFLOW_API_KEY,
          inputs: { image: { type: "base64", value: imageBase64 } },
        }),
      }
    );
    const data = await response.json();
    res.status(200).json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Roboflow 呼叫失敗" });
  }
};
