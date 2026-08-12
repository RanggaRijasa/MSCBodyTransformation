const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

module.exports = defineConfig([
  ...expoConfig,
  {
    ignores: ['dist/**', 'coverage/**', 'playwright-report/**', 'test-results/**'],
  },
  {
    files: ['src/**/*.{ts,tsx}', 'tests/**/*.ts'],
    rules: {
      'import/namespace': 'off',
      'import/no-duplicates': 'off',
      'import/no-unresolved': 'off',
      'no-restricted-imports': [
        'error',
        {
          paths: [
            {
              name: 'phosphor-react-native',
              message: 'Gunakan wrapper semantic MSCIcon.',
            },
          ],
        },
      ],
    },
  },
]);
