const core = require('@actions/core');
const github = require('@actions/github');
const semver = require('semver')

try {
  const myToken = core.getInput('myToken');
  const octokit = github.getOctokit(myToken);
  octokit.rest.repos.listReleases({
    owner: 'istio',
    repo: 'istio',
  }).then(result => {
        // core.setOutput("foo", result.data)
        const relmap = new Map();
        result.data.forEach( rel => relmap.set(rel.tag_name, rel));
        max = semver.parse(semver.maxSatisfying(Array.from(relmap.keys()), "v1"));
        core.setOutput("version", max.version);
        core.setOutput("major", max.major);
        core.setOutput("minor", max.minor);
        core.setOutput("patch", max.patch);
      })
      .catch(error => core.setFailed(error.message));
} catch (error) {
  core.setFailed(error.message);
}
