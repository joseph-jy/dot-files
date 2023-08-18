local jdk_home ="/opt/homebrew/Cellar/openjdk@17/17.0.8"
return {
  settings = {
    cmd_env = {
      PATH = jdk_home .. "/bin:" .. vim.env.PATH,
      JAVA_HOME = jdk_home,
    },
  },
}
