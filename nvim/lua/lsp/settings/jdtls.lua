local lombok_jar = vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar"
local lombok_arg = "-javaagent:" .. lombok_jar

if vim.uv.fs_stat(lombok_jar) then
  local current_args = vim.env.JDTLS_JVM_ARGS or ""

  if not current_args:find("lombok.jar", 1, true) then
    vim.env.JDTLS_JVM_ARGS = current_args == "" and lombok_arg or (current_args .. " " .. lombok_arg)
  end
end

return {}
