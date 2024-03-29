-- encoding:utf-8

local traits = nil
local ffi = require'ffi'

if (ffi.os == 'OSX') then
  traits = {
    runtimePath = 'lib/librime.1.dylib',
    dataPath = 'var',
    userPath = 'tmp',
    name= "rime-lua",
    code_name = 'rime-lua',
    version = '0.0.0'
  }
elseif ffi.os == 'Linux' then
  traits = {
    runtimePath = 'lib/librime.1.so',
    dataPath = 'var',
    userPath = 'tmp',
    name= "rime-lua",
    code_name = 'rime-lua',
    version = '0.0.0'
  }
elseif ffi.os == 'Windows' then
  traits = {
    runtimePath = [[e:\Totalcmd\Tools\RIME\weasel-0.9.30\rime.dll]],
    dataPath = [[e:\Totalcmd\Tools\RIME\weasel-0.9.30\data]],
    userPath = [[e:\work\rime\rime_simp]],
    name= "小狼毫",
    code_name = 'Weasel',
    version = '0.9.30'
  }
end

return {
  cPoint = 'ipc://LuaIME',
  traits = traits,
  ime = {
    name="全能拼音",
    version= "0.3.0",
    guid= "{A381D463-9338-4FBD-B83D-66FFB03523B3}",
    locale= "zh-CHS",
    fallbackLocale= "zh-CN",
    icon= "e:\\work\\zhaozg\\rime\\LuaIME\\Resource\\luaIME.ico"
  }
}
