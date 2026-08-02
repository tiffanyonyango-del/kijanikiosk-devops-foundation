const { greet } = require("../src/app");

test("greets a user", () => {
  expect(greet("Tiffany")).toBe("Hello, Tiffany!");
});