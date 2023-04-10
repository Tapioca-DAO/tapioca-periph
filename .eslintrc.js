module.exports = {
    env: {
        browser: false,
        es2021: true,
        mocha: true,
        node: true,
    },
    extends: [
        'plugin:@typescript-eslint/recommended',
        'plugin:prettier/recommended',
    ],
    parser: '@typescript-eslint/parser',
    plugins: ['@typescript-eslint', 'prettier'],
    root: true,
    parserOptions: {
        ecmaVersion: 12,
    },
    rules: {
        '@typescript-eslint/no-explicit-any': ['off'],
        'prettier/prettier': [
            'error',
            {
                trailingComma: 'all',
                singleQuote: true,
                printWidth: 80,
                endOfLine: 'auto',
                useTabs: false,
                tabWidth: 4,
            },
        ],
        'comma-dangle': [2, 'always-multiline'],
        semi: ['error', 'always'],
        'comma-spacing': ['error', { before: false, after: true }],
        quotes: ['error', 'single'],
        indent: 'off',
        'key-spacing': ['error', { afterColon: true }],
        'no-multi-spaces': ['error'],
        'no-multiple-empty-lines': ['error', { max: 2 }],
        '@typescript-eslint/ban-ts-comment': 'off',
    },
};
