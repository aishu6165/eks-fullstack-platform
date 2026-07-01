const express = require("express");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  PutCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");

const app = express();
app.use(express.json());

const REGION = process.env.AWS_REGION || "us-east-1";
const TABLE = process.env.TABLE_NAME;

// Credentials come from EKS Pod Identity - nothing hardcoded here.
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));

app.get("/api/healthz", (_req, res) => res.status(200).json({ status: "ok" }));

app.get("/api/items", async (_req, res) => {
  try {
    const out = await ddb.send(new ScanCommand({ TableName: TABLE, Limit: 50 }));
    res.json(out.Items || []);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

app.post("/api/items", async (req, res) => {
  const { id, name } = req.body || {};
  if (!id || !name) return res.status(400).json({ error: "id and name required" });
  // Table has a composite key, so every item needs both pk and sk.
  const item = { pk: id, sk: "ITEM", name, created_at: new Date().toISOString() };
  try {
    await ddb.send(new PutCommand({ TableName: TABLE, Item: item }));
    res.status(201).json(item);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`backend listening on ${PORT}`));
