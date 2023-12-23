describe("config test", function()
  package.path = '?/init.lua;?.lua;'..package.path
  local rime, traits
  local _ref = 0

  setup(function()
    if not rime then
      local profile = require('profile')
      rime = require'rime'(assert(profile.traits.runtimePath))
      traits = rime:toTraits(
        assert(profile.traits.dataPath),
        assert(profile.traits.userPath),
        assert(profile.traits.name),
        assert(profile.traits.code_name),
        assert(profile.traits.version)
      )

      assert(rime:initialize(traits))
    end
    _ref = _ref + 1
  end)

  teardown(function()
    _ref = _ref - 1
    if _ref == 0 then
      rime:finalize()
      rime = nil
    end
  end)

  it("info", function()
    assert.equal("1.9.0", rime:Version())
    assert.equal("string", type(rime:SharedDataDir()))
    assert.equal("string", type(rime:UserDataDir()))
    assert.equal("string", type(rime:SyncDir()))
    assert.equal("string", type(rime:UserId()))
    assert.equal("string", type(rime:UserDataSyncDir()))
    assert.equal("table",  type(rime:Schemas()))
  end)

  it("maintance", function()
    assert(rime:is_maintenance_mode()==false)

    assert(rime:start_maintenance(false)==false)
    assert(rime:start_maintenance(true)==true)
    rime:join_maintenance_thread()

    rime:deployer_initialize(traits)
    rime:prebuild()
    rime:deploy()

    rime:deploy_schema('luna_pinyin')

    rime:deploy_config_file('default','1.3.1')
    --rime:sync_user_data()
  end)


  it("simple list", function()
    local config = rime:ConfigCreate(true)
    assert(config:create_map('list'))
    assert(config:size('list')==0)
    local list = config:item('list')
    list:int('1','1')
    list:int('2','2')
    list:int('3','3')
    assert(list:size('list')==0)
    -- for v in config:iterator('list') do
    --   rime.utils.print_r(v)
    -- end
  end)

  it("schema_list", function()
    local config = rime:ConfigOpen('default')
    assert(config:size('schema_list')>0)
    local list = config:item('schema_list')
    assert(list)
    --print(config:iterator('schema_list'))
    -- for v in config:iterator('schema_list') do
    --   rime.utils.print_r(v)
    -- end
  end)

  it("map", function()
    local config = rime:ConfigOpen('default')
    assert(config:size('switcher')==0)
    local list = config:item('switcher')
    assert(list)
    -- rime.utils.print_r(list)
    -- print(config:iterator('switcher'))
    -- for v in config:iterator('switcher') do
    --   rime.utils.print_r(v)
    -- end
  end)
end)
