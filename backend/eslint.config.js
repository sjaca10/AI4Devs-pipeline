const prettier = require('eslint-plugin-prettier/recommended');

module.exports = [
  {
    ...prettier,
    ignores: ['dist/', 'node_modules/'],
  },
];
