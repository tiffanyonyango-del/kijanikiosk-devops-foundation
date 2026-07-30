const fs = require("fs");
const path = require("path");

const distDir = "dist";

if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir);
}

const filesToCopy = [
  "index.js",
  "app.js"
];

filesToCopy.forEach(file => {
  fs.copyFileSync(
    path.join("src", file),
    path.join(distDir, file)
  );
});

fs.copyFileSync("package.json", "dist/package.json");

console.log("Build completed successfully.");