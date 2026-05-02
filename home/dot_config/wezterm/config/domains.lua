local platform = require('utils.platform')

---@type Config
local options = {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {},

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {},
}

if platform.is_win then
   options.ssh_domains = {
      {
         name = 'ssh:wsl',
         username = 'prettycation',
         remote_address = 'localhost',
         multiplexing = 'None',
         default_prog = { 'fish', '-l' },
         assume_shell = 'Posix',
      },
      {
         name = 'ssh:arch-zsh',
         remote_address = '127.0.0.1',
         username = 'shiro',
         multiplexing = 'None',
         assume_shell = 'Posix',
         default_prog = { 'zsh', '-l' },
      },
   }

   options.wsl_domains = {
      {
         name = 'wsl:ubuntu-fish',
         distribution = 'Ubuntu',
         username = 'prettycation',
         default_cwd = '/home/prettycation',
         default_prog = { 'fish', '-l' },
      },
      {
         name = 'wsl:ubuntu-bash',
         distribution = 'Ubuntu',
         username = 'prettycation',
         default_cwd = '/home/prettycation',
         default_prog = { 'bash', '-l' },
      },
      {
         name = 'wsl:arch-zsh',
         distribution = 'Arch',
         username = 'shiro',
         default_cwd = '/home/shiro',
         default_prog = { 'zsh', '-l' },
      },
   }
end

return options
