describe("basic test", function()
  package.path = '?/init.lua;?.lua;'..package.path
  local rime, traits, session, schema
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

      assert(rime:initialize(traits, false, function() end))
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
    assert.equals("1.9.0", rime:Version())
    assert.equals("string", type(rime:SharedDataDir()))
    assert.equals("string", type(rime:UserDataDir()))
    assert.equals("string", type(rime:SyncDir()))
    assert.equals("string", type(rime:UserId()))
    assert.equals("string", type(rime:UserDataSyncDir()))
    assert.equals("table",  type(rime:Schemas()))
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

  it("session", function()
    session = rime:SessionCreate()
    rime:SessionCleanup()
    assert(session:exist())
    rime:SessionCleanup(true)
    assert(session:exist()==false)
  end)

  it("schema", function()
    session = rime:SessionCreate()
    local _schema = session:Schema()
    assert.equals('string', type(_schema))
    if _schema ~= 'luna_pinyin' then
      schema = 'luna_pinyin'
      session:Schema(schema)
      schema = session:Schema()
    end
  end)

  it("pinyin ascii_mode", function()
    rime.utils.printInfo(session)
    schema = session:Schema()
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
  end)

  it("pinyin ime", function()
    --disable ascii_mode
    assert(session:Schema('luna_pinyin'))
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
  end)

end)
