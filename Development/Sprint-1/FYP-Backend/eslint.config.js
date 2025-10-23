import js from "@eslint/js";
import globals from "globals";
import prettierConfig from "eslint-config-prettier";
import prettierPlugin from "eslint-plugin-prettier";
import jestPlugin from "eslint-plugin-jest";

export default [
  {
    files: ["**/*.{js,mjs,cjs}"],
    plugins: {
      jest: jestPlugin,
      prettier: prettierPlugin
    },
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.jest
      }
    },
    rules: {
      ...js.configs.recommended.rules,
      ...jestPlugin.configs.recommended.rules,
      camelcase: "warn",
      curly: "error",
      "no-console": "warn",
      "prettier/prettier": "error"
    }
  },
  prettierConfig
];
