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
      print('yyy', _ref)
      rime:finalize()
      rime = nil
    end
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
