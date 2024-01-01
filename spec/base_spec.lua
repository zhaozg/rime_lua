expose("an exposed test", function()
  package.path = '?/init.lua;?.lua;'..package.path
  local profile = require('profile')
  local rime = require'rime'(assert(profile.traits.runtimePath))
  local traits, _ref = nil, 0

  setup(function()
    traits = rime:toTraits(
      assert(profile.traits.dataPath),
      assert(profile.traits.userPath),
      assert(profile.traits.name),
      assert(profile.traits.code_name),
      assert(profile.traits.version)
    )

    assert(rime:initialize(traits, false, function() end))
    _ref = _ref + 1
  end)

  teardown(function()
    _ref = _ref - 1
    if _ref == 0 then
      rime:finalize()
      rime = nil
    end
  end)

  describe("basic test", function()
    local session, schema

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
      assert('string' == type(_schema))
      if _schema ~= 'luna_pinyin' then
        schema = 'luna_pinyin'
        session:Schema(schema)
        schema = session:Schema()
      end
    end)

    it("pinyin ascii_mode", function()
      schema = session:Schema()
      session:Schema(schema)
      assert(schema==session:Schema())

      rime:deploy_schema('luna_pinyin')
      --change schema
      local schema_list = rime:Schemas()
      -- rime.utils.print_r(schema_list)

      local schemaid = schema_list[#schema_list].id
      assert(schemaid)
      session:Schema(schema)
      assert(schema==session:Schema())

      local v = session:Option('ascii_mode')
      session:Option('ascii_mode', not v)
      assert(v~=session:Option('ascii_mode'))
      session:Option('ascii_mode', v)

      --disable ascii_mode
      session:Option('ascii_mode', false)
      local list = session:Candidates()
      -- rime.utils.print_r(list,'list')

      assert(session:simulate('abcd')==true)
      -- rime.utils.printInfo(session)
      list = session:Candidates()
      assert(type(list)=='table')
      assert(#list > 0)
      assert(session:Select(1))
      local commit = session:Commit()
      assert(commit=='啊不错的' or '安部彻的')
    end)

    it("pinyin ime", function()
      --disable ascii_mode
      assert(session:Schema('luna_pinyin'))
      session:Option('ascii_mode', false)
      local list

      assert(session:simulate('xiguanjiuhaole')==true)
      -- rime.utils.printInfo(session)
      list = session:Candidates()
      assert(#list > 0)
      --rime.utils.print_r(list, "习惯就好了")
      assert(session:Select(1))
      assert.equal("习惯就好了", session:Commit())

      assert(session:simulate('burejinsiji')==true)
      -- rime.utils.printInfo(session)
      list = session:Candidates()
      assert(#list > 0)
      --rime.utils.print_r(list, "布热津斯基")
      assert(session:Select(1))
      assert.equal("布热津斯基", session:Commit())

      assert(session:simulate('shurufangshizhuanhuanjian')==true)
      --rime.utils.printInfo(session)
      list = session:Candidates()
      assert(session:Select(1))
      assert.equal('输入方式转换键', session:Commit())

      assert(session:simulate('chujiangkongwan')==true)
      --rime.utils.printInfo(session)
      list = session:Candidates()
      assert(session:Select(1))
      assert.equal('楚江空晚', session:Commit())

      local seq = "qiushuigongchangtianyise"
      for i=1,#seq do
        local keycode = seq:byte(i)
        session:process(keycode)
        --rime.utils.printInfo(session)
      end
      assert(session:Select(1))
      assert(session:commit())
      assert.equal('秋水共长天一色', session:Commit())
    end)

    it("pinyin_fluency ime", function()
      --disable ascii_mode
      assert(session:Schema('luna_pinyin_fluency'))
      session:Option('ascii_mode', false)
      session:Option('simplification', true)

      assert(session:simulate('xiguanjiuhaole')==true)
      --rime.utils.printInfo(session)
      --local list = session:Candidates()
      --assert(#list > 0)
      assert(session:Select(1))
      assert(session:commit())
      assert.equal('习惯就好了', session:Commit())

      local seq = "yitiaodahebolang"
      for i=1,#seq do
        local keycode = seq:byte(i)
        session:process(keycode)
      end
      assert(session:Select(1))
      assert(session:commit())
      --rime.utils.printInfo(session)
      assert.equal('一条大河波浪', session:Commit())
    end)

    it("double_pinyin ime", function()
      --disable ascii_mode
      assert(session:Schema('double_pinyin'))
      session:Option('ascii_mode', false)

      assert(session:simulate('duguqqbl')==true)
      --rime.utils.printInfo(session)
      local list = session:Candidates()
      assert(#list > 0)
      --rime.utils.print_r(list, "习惯就好了")
      assert(session:Select(1))
      assert(session:commit())
      local commit = assert(session:Commit())
      assert.equal("独孤求败", commit)
    end)

  end)
end)
