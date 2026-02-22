
const express = require("express");
const mysql = require("mysql2");
const bcrypt = require("bcrypt");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: "admin",
  password: "Password123!",
  database: "tobacco_store"
});

db.connect(err => {
  if (err) console.log("DB Error:", err);
  else console.log("Connected to DB");
});

app.post("/signup", async (req, res) => {
  const { username, email, password } = req.body;
  const hash = await bcrypt.hash(password, 10);

  db.query(
    "INSERT INTO users (username,email,password) VALUES (?,?,?)",
    [username, email, hash],
    (err) => {
      if (err) return res.status(400).send("User exists");
      res.send("Registered");
    }
  );
});

app.post("/login", (req, res) => {
  const { email, password } = req.body;

  db.query("SELECT * FROM users WHERE email=?", [email], async (err, result) => {
    if (!result || result.length === 0) return res.status(400).send("Invalid user");

    const match = await bcrypt.compare(password, result[0].password);
    if (!match) return res.status(400).send("Wrong password");

    res.send("Login success");
  });
});

app.get("/products", (req, res) => {
  db.query("SELECT * FROM products", (err, results) => {
    res.json(results);
  });
});

app.listen(3000, () => console.log("Server running on port 3000"));
