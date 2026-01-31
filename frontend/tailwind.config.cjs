/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    // Dynamically fetched effect UI/logic source; Tailwind must scan these files
    // so their utility classes (including arbitrary values) are present at runtime.
    './public/effects/**/*.{js,ts,jsx,tsx}',
  ],
  // WebF supports a constrained subset of CSS. Tailwind's preflight injects
  // a lot of base rules (e.g. cursor, appearance, tap-highlight-color) that are
  // outside our supported property list, so disable it.
  corePlugins: {
    preflight: false,
    textOpacity: false,
    backgroundOpacity: false,
    borderOpacity: false,
    divideOpacity: false,
    placeholderOpacity: false,
    ringOpacity: false,
  },
  darkMode: 'media',
  theme: {
    extend: {},
  },
  plugins: [],
}
