const github = require('@actions/github');
const core = require('@actions/core');

const { IncomingWebhook } = require('@slack/webhook');

const context = github.context;

const SENSITIVE_PATTERNS = [
  /app\.shopify\.com/g,
  /admin\.shopify\.com/g,
];

const myToken = core.getInput(process.env.GITHUB_TOKEN);
const octokit = github.getOctokit(myToken);

const slackWebhook = new IncomingWebhook(process.env.SLACK_WEBHOOK_URL);

async function sendSlackNotification(message) {
  await slackWebhook.send({ text: message });
}

async function checkForSensitiveInfo() {
  const payload = context.payload;

  if (payload.issue) {
    await checkIssue(payload.issue.number);
  } else if (payload.pull_request) {
    await checkPR(payload.pull_request.number);
  } else if (payload.comment) {
    if (payload.issue) {
      await checkIssue(payload.issue.number);
    } else if (payload.pull_request) {
      await checkPR(payload.pull_request.number);
    }
  } else if (payload.review) {
    await checkPR(payload.pull_request.number);
  }
}

async function checkIssue(issueNumber) {
  const issue = await octokit.rest.issues.get({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: issueNumber,
  });

  if (issue.data.body) {
    await checkAndSanitize(issue.data.body, issueNumber, 'issue');
  }

  const comments = await octokit.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: issueNumber,
  });

  for (const comment of comments.data) {
    if (comment.body) {
      await checkAndSanitize(comment.body, comment.id, 'comment');
    }
  }
}

async function checkPR(pullNumber) {
  const pullRequest = await octokit.rest.pulls.get({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pullNumber,
  });

  if (pullRequest.data.body) {
    await checkAndSanitize(pullRequest.data.body, pullNumber, 'pull_request');
  }

  const prComments = await octokit.rest.pulls.listReviewComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pullNumber,
  });

  for (const prComment of prComments.data) {
    if (prComment.body) {
      await checkAndSanitize(prComment.body, prComment.id, 'pr_comment');
    }
  }
}

async function checkAndSanitize(body, id, type) {
  for (const pattern of SENSITIVE_PATTERNS) {
    if (pattern.test(body)) {
      const sanitizedBody = body.replace(pattern, '[REDACTED]');
      if (type === 'issue') {
        await octokit.rest.issues.update({
          owner: context.repo.owner,
          repo: context.repo.repo,
          issue_number: id,
          body: sanitizedBody,
        });
      } else if (type === 'comment') {
        await octokit.rest.issues.updateComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          comment_id: id,
          body: sanitizedBody,
        });
      } else if (type === 'pull_request') {
        await octokit.rest.pulls.update({
          owner: context.repo.owner,
          repo: context.repo.repo,
          pull_number: id,
          body: sanitizedBody,
        });
      } else if (type === 'pr_comment') {
        await octokit.rest.pulls.updateReviewComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          comment_id: id,
          body: sanitizedBody,
        });
      }

      const url = `https://github.com/${context.repo.owner}/${context.repo.repo}/${type === 'issue' || type === 'comment' ? 'issues' : 'pull'}/${id}`;
      await sendSlackNotification(`Sensitive information was found and removed from ${type} #${id}. [Link](${url})`);
    }
  }
}

checkForSensitiveInfo().catch(console.error);
