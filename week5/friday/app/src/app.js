const express = require("express");
const packageJson = require("../package.json");

const app = express();

const version = process.env.APP_VERSION || packageJson.version;

console.log("APP_VERSION =", process.env.APP_VERSION);

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to KijaniKiosk API"
  });
});

app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    version
  });
});

module.exports = app;