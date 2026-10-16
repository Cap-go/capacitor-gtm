// Used by test.yml (same-repo PRs) and pr_beta_prompt.yml (fork PRs).
module.exports = async function upsertPrBetaComment({ github, context }) {
  const marker = '<!-- pr-beta-publish -->';
  const sameRepo = process.env.IS_SAME_REPO === 'true';
  const pr = context.payload.pull_request;
  const body = sameRepo
    ? [
        marker,
        '',
        '## Beta npm build',
        '',
        'Maintainers can publish this PR to npm for fast testing.',
        '',
        'Comment `/publish-beta` after the PR checks are green.',
        '',
        'The workflow will:',
        '- publish a prerelease package on the `beta` tag',
        `- add a pinned \`pr-${pr.number}\` dist-tag for this exact PR build`,
        '- update this comment with the install command',
        '',
        'Security note: beta publish is only enabled for branches inside this repository.',
      ].join('\n')
    : [
        marker,
        '',
        '## Beta npm build',
        '',
        'This PR comes from a fork, so beta publish is disabled for security.',
        '',
        'If you need a beta package, move the branch into this repository first.',
      ].join('\n');

  const { owner, repo } = context.repo;
  const comments = await github.paginate(github.rest.issues.listComments, {
    owner,
    repo,
    issue_number: pr.number,
    per_page: 100,
  });

  const existing = comments.find((comment) => comment.user.type === 'Bot' && comment.body.includes(marker));

  if (existing) {
    await github.rest.issues.updateComment({
      owner,
      repo,
      comment_id: existing.id,
      body,
    });
  } else {
    await github.rest.issues.createComment({
      owner,
      repo,
      issue_number: pr.number,
      body,
    });
  }
};
