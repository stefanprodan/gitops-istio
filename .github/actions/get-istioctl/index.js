const core = require('@actions/core');
// const github = require('@actions/github');
const semver = require('semver');
const os = require('os');
const { Octokit } = require("@octokit/rest");
const util = require("util")

try {
  // const myToken = core.getInput('myToken');
  // const octokit = github.getOctokit(myToken);
  const octokit = new Octokit()
  octokit.rest.repos.listReleases({
    owner: 'istio',
    repo: 'istio',
  }).then(result => {
    const relmap = new Map();
    result.data.forEach( rel => relmap.set(rel.tag_name, rel));
    max = semver.parse(semver.maxSatisfying(Array.from(relmap.keys()), "v1"));
    core.setOutput("version", max.version);
    core.setOutput("major", max.major);
    core.setOutput("minor", max.minor);
    core.setOutput("patch", max.patch);
    let artifacts = relmap.get(max.raw).assets.reduce(function(map,obj) {
      map.set(obj.name, obj);
     return map;
    }, new Map());
    extension = '';
    osvar = core.getInput("os")
    arch = "-" + core.getInput("arch")
    if (arch === "-local") {
      switch(os.arch()){
        case 'arm':
          arch = "-armv7"
          break;
        case 'arm64':
          break;
        default:
          arch = "-amd64"
      }
    }
    if (osvar === "local") {
      switch(os.platform()) {
        case 'darwin':
          osvar = "osx";
          extension = '.tar.gz'
          if (arch !== '-arm64') {
            arch = ''
          }
          break;
        case 'win32':
          osvar = "win"
          extension = '.zip'
          break;
        default:
          osvar = "linux"
          extension = '.tar.gz'
          break;
      }
    }
    istioctlkey = util.format("%s-%s-%s%s%s", "istioctl", max.raw, osvar, arch, extension)
    istiokey = util.format("%s-%s-%s%s%s", "istio", max.raw, osvar, arch, extension)
    core.setOutput("istioctl-url", artifacts.get(istioctlkey).browser_download_url)
    core.setOutput("istio-url", artifacts.get(istiokey).browser_download_url)
  })
  .catch(error => core.setFailed(error.message));
} catch (error) {
  core.setFailed(error.message);
}
