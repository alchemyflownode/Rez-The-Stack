module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',      // A new feature
        'fix',       // A bug fix
        'docs',      // Documentation only changes
        'style',     // Changes that don't affect code (formatting, missing semicolons, etc)
        'refactor',  // Code change that neither fixes a bug nor adds a feature
        'perf',      // Code change that improves performance
        'test',      // Adding or updating tests
        'ci',        // Changes to CI/CD configuration
        'chore',     // Changes to build process, dependencies, or tooling
        'revert',    // Revert a previous commit
        'security',  // Security fix or improvement
        'a11y',      // Accessibility improvements
      ],
    ],
    'type-case': [2, 'always', 'lowercase'],
    'type-empty': [2, 'never'],
    'scope-case': [2, 'always', 'lowercase'],
    'subject-case': [2, 'always', ['sentence-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'always', '.'],
    'header-max-length': [2, 'always', 100],
  },
};
