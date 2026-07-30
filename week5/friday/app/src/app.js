const express = require("express");
const packageJson = require("../package.json");

const app = express();

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to KijaniKiosk API"
  });
});

app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    version: packageJson.version
  });
});

module.exports = app;