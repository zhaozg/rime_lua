describe("luna_pinyin test", function()
  package.path = '?/init.lua;?.lua;'..package.path
  local rime, traits, session
  local _ref = 0
  local schema = "luna_pinyin_fluency"
  -- 以空格分詞、標點或回車上屏。

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
      rime:deploy_schema(schema)
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

  it("schema", function()
    session = rime:SessionCreate()
    local _schema = session:Schema()
    assert('string' == type(_schema))
    session:Schema(schema)
    assert(schema == session:Schema())

    local status = session:Status()
    assert.are.same(status, {
      disabled = false,
      composing = false,
      ascii_mode = true,
      full_shape = false,
      simplified = true,
      traditional = false,
      ascii_punct = false,
      id = schema,
      name = '朙月拼音·語句流'
    })
  end)

  it("pinyin ascii_mode", function()
    local v = session:Option('ascii_mode')
    session:Option('ascii_mode', not v)
    assert(v~=session:Option('ascii_mode'))

    --disable ascii_mode
    session:Option('ascii_mode', false)
    local list = session:Candidates()

    assert(session:simulate('abcd')==true)
    local status = session:Status()
    assert.are.same(status, {
      disabled = false,
      composing = true,
      ascii_mode = false,
      full_shape = false,
      simplified = true,
      traditional = false,
      ascii_punct = false,
      id = schema,
      name = '朙月拼音·語句流'
    })

    list = session:Candidates()
    assert(type(list)=='table')
    assert(#list > 0)
    assert(session:Select(1))
    assert(session:commit())
    local commit = assert(session:Commit())
    assert.equal("啊不错的", commit)
  end)

  it("pinyin ime", function()
    --disable ascii_mode
    assert(session:Schema(schema))
    session:Option('ascii_mode', false)
    local list

    assert(session:simulate('xiguanjiuhaole')==true)
    list = session:Candidates()
    assert(#list > 0)
    assert(session:Select(1))
    assert(session:commit())
    local commit = session:Commit()
    assert.equal("习惯就好了", commit)

    assert(session:simulate('burejinsiji')==true)
    list = session:Candidates()
    assert(#list > 0)
    assert(session:Select(1))
    assert(session:commit())
    commit = session:Commit()
    assert.equal("布热津斯基", commit)

    assert(session:simulate('shurufangshizhuanhuanjian')==true)
    list = session:Candidates()
    assert(session:Select(1))
    assert(session:commit())
    commit = session:Commit()
    assert.equal("输入方式转换键", commit)

    assert(session:simulate('chujiangkongwan')==true)
    list = session:Candidates()
    assert(session:Select(1))
    assert(session:commit())
    commit = session:Commit()
    assert.equal("楚江空晚", commit)

    local seq = "yitiaodahebolangkuanfengchuidaohuaxiangliang'an"
    for i=1,#seq do
      local keycode = seq:byte(i)
      session:process(keycode)
    end

    local selected = {2, 2, 4, 2, 2, 1}
    repeat
      local idx = table.remove(selected, 1)
      if idx then
        --rime.utils.printInfo(session)
        assert(session:Select(idx))
      end
    until not idx
    assert(session:commit())

    assert.equal('一条大河波浪宽风吹稻花香两岸', session:Commit())
  end)
end)
