const { spawnSync } = require("child_process");

exports.handler = async (event) => {
  await require("lambda-git")();
  const clone = spawnSync(
    "git",
    [
      "clone",
      "git@github.com:LBHackney-IT/coronavirus-here-to-help-frontend.git",
    ],
    {
      cwd: "/tmp",
    }
  );
  console.log(clone.output.toString());
  const response = {
    statusCode: 200,
    body: JSON.stringify(clone.output.toString()),
  };
  return response;
};
