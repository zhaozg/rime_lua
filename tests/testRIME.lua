package.path = '?/init.lua;?.lua;'..package.path
local luaunit = require('luaunit')
local profile = require('profile')

local lu = luaunit.LuaUnit.new()

local rime = require'rime'(assert(profile.traits.runtimePath))
------------------------------------------------------------------------------
local ffi = require'ffi'

------------------------------------------------------------------------------
local traits = rime:toTraits(
  assert(profile.traits.dataPath),
  assert(profile.traits.userPath),
  assert(profile.traits.name),
  assert(profile.traits.code_name),
  assert(profile.traits.version)
)

assert(rime:initialize(traits))

TestRime = {}

function TestRime:testBasic()
  print('Version\t',            rime:Version())
  print('SharedDataDir',        rime:SharedDataDir())
  print('UserDataDir',          rime:UserDataDir())
  print('SyncDir\t',            rime:SyncDir())
  print('UserId\t',             rime:UserId())
  print('UserDataSyncDir',      rime:UserDataSyncDir())
  assert(type(rime:Schemas())=='table')
  print('----SchemaList----')
  rime.utils.print_r(rime:Schemas())
  print()
end

local function cost(fn, title)
  local bgn = os.time()
  fn()
  print(string.format('%s: cost %f secs',title,(os.time()-bgn)/1000))
end

function TestRime:xtestMaintance()
  assert(rime:is_maintenance_mode()==false)

  cost(function()
    assert(rime:start_maintenance(false)==false)
    assert(rime:start_maintenance(true)==true)
    rime:join_maintenance_thread()
  end,'maintance')

  cost(function()
    rime:deployer_initialize(traits)
  end,'deployer_initialize')

  cost(function()
    rime:prebuild()
  end,'prebuild')
  cost(function()
    rime:deploy()
  end,'deploy')

  cost(function()
    rime:deploy_schema('luna_pinyin')
  end,'deploy_schema')

  cost(function()
    rime:deploy_config_file('default','1.3.1')
  end,'deploy_config_file')
  cost(function()
    rime:sync_user_data()
  end,'sync_user_data')
end

function TestRime:testSession()
  local session = rime:SessionCreate()
  rime:SessionCleanup()
  assert(session:exist())
  rime:SessionCleanup(true)
  assert(session:exist()==false)
end

TestSession = {}

function TestSession:setup()
  self.session = rime:SessionCreate()
  local schema = self.session:Schema()
  print('current:',schema)
  if schema ~= 'luna_pinyin' then
    schema = 'luna_pinyin'
    self.session:Schema(schema)
  end
end

function TestSession:testBasic()
  local session = self.session
  rime.utils.printInfo(session)
  local schema = session:Schema()
  print('current:',schema)
  session:Schema(schema)
  assert(schema==session:Schema())

  rime:deploy_schema('luna_pinyin')
  --change schema
  local schema_list = rime:Schemas()
  rime.utils.print_r(schema_list)

  local schemaid = schema_list[#schema_list].id
  session:Schema(schema)
  assert(schema==session:Schema())

  local v = session:Option('ascii_mode')
  session:Option('ascii_mode', not v)
  assert(v~=session:Option('ascii_mode'))
  session:Option('ascii_mode', v)

  --disable ascii_mode
  session:Option('ascii_mode', false)
  local list = session:Candidates()
  rime.utils.print_r(list,'list')

  assert(session:simulate('abcd')==true)
  rime.utils.printInfo(session)
  list = session:Candidates()
  assert(type(list)=='table')
  rime.utils.print_r(list,'list of abcd')
  assert(session:Select(1))
  print(session:Commit())
  rime.utils.printInfo(session)
end

function TestSession:testProcess()
  local session = self.session
  --disable ascii_mode
  if session:Schema('luna_pinyin') then
    session:Option('ascii_mode', false)
    local list

    rime.utils.printInfo(session)
    assert(session:simulate('xiguanjiuhaole')==true)
    list = session:Candidates()
    rime.utils.print_r(list, "习惯就好了")
    assert(session:Select(1))
    print(session:Commit())

    assert(session:simulate('burejinsiji')==true)
    rime.utils.printInfo(session)
    list = session:Candidates()
    rime.utils.print_r(list, "布热津斯基")
    assert(session:Select(1))
    print(session:Commit())

    assert(session:simulate('shurufangshizhuanhuanjian')==true)
    rime.utils.printInfo(session)
    list = session:Candidates()
    assert(session:Select(1))
    print(session:Commit())

    assert(session:simulate('chujiangkongwan')==true)
    rime.utils.printInfo(session)
    list = session:Candidates()
    assert(session:Select(1))
    print(session:Commit())


    local seq = 'yitiaodaheboliangkuanfengchuidaohuaxiangliaan'
    for i=1,#seq do
      local keycode = seq:byte(i)
      session:process(keycode)
      --rime.utils.printInfo(session)
    end
    assert(session:Select(1))
    print(session:Commit())
  else
    print('skip test luna_pinyin')
  end
end

TestConfig = {}

function TestConfig:testBasic()
  local config = rime:ConfigCreate(true)
  assert(config[0]:create_map('list'))
  assert(config[0]:size('list')==0)
  local list = config[0]:item('list')
  list[0]:int('1','1')
  list[0]:int('2','2')
  list[0]:int('3','3')
  assert(list[0]:size('list')==0)
  for v in config[0]:iterator('list') do
    rime.utils.print_r(v)
  end
end

function TestConfig:testDefaultList()
  local config = rime:ConfigOpen('default')
  assert(config[0]:size('schema_list')>0)
  local list = config[0]:item('schema_list')
  assert(list)
  rime.utils.print_r(list)
  print(config[0]:iterator('schema_list'))
  for v in config[0]:iterator('schema_list') do
    rime.utils.print_r(v)
  end
end

function TestConfig:testDefaultMap()
  local config = rime:ConfigOpen('default')
  assert(config[0]:size('switcher')==0)
  local list = config[0]:item('switcher')
  assert(list)
  rime.utils.print_r(list)
  print(config[0]:iterator('switcher'))
  for v in config[0]:iterator('switcher') do
    rime.utils.print_r(v)
  end
end

--lu:setOutputType("tap")
os.exit( lu:runSuite() )
