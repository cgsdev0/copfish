/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./pages/**/*.sh", "./*.sh"],
  darkMode: "media",
  theme: {
    extend: {
      keyframes: {
        grow: {
          "0%": { transform: "scaleX(0)" },
          "100%": { transform: "scaleX(1)" },
        },
      },
      animation: {
        grow: "grow 1s ease-in-out forwards",
      },
    },
    fontSize: {
      base: "1rem",
      lg: "1.5rem",
      xl: "2rem",
    },
  },
  plugins: [],
};
