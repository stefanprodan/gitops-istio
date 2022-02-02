const core = require('@actions/core');
const github = require('@actions/github');
const semver = require('semver')

try {
  const octokit = github.getOctokit("");
  const releases = octokit.rest.repos.listReleases({
    "istio",
    "istio",
  });
  const relmap = new Map();
  releases.forEach( rel => relmap.set(rel.tag_name, rel));
  max = semver.maxSatisfying(Array.from(relmap.keys()), "v1")
  core.setOutput("version", max.version);
  core.setOutput("major", max.major)
  core.setOutput("minor", max.minor)
  core.setOutput("patch", max.patch)
} catch (error) {
  core.setFailed(error.message)
}
