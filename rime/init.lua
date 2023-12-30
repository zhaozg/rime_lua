local ffi = require 'ffi'
------------------------------------------------------------------------------
--!help utilities
local function IsNULL(val) return val == nil end
local function IsFalse(val) return val == ffi.C.False end
local function IsEmpty(s) return s == nil or ffi.string(s) == '' end

local function toBoolean(val)
  assert(val == ffi.C.True or val == ffi.C.False)
  return val ~= ffi.C.False
end

local function toBool(val)
  assert(type(val) == 'boolean')
  return val and ffi.C.True or ffi.C.False
end

local function toString(v, len)
  if type(v) == 'cdata' then
    if (v == nil) then
      return nil
    else
      return ffi.string(v, len)
    end
  else
    return tostring(v)
  end
end

local function toPointer(s)
  return ffi.cast('intptr_t', ffi.cast('void*', s))
end

local function StructCreate(ctype, gc)
  local ret = ffi.new(ctype)
  ffi.fill(ret, 0, ffi.sizeof(ctype))
  if gc then
    ret = ffi.gc(ret, gc)
  end
  return ret
end

local function StructCreateInit(ctype, gc)
  local ret = StructCreate(ctype, gc)
  ret[0].data_size = ffi.sizeof(ctype) - ffi.sizeof('int')
  return ret
end

------------------------------------------------------------------------------
-- configuration -------------------------------------------------------------

local mtRimeConfig
mtRimeConfig = {
  __index = {
    bool = function(self, key, val)
      if type(val) == 'nil' then
        return toBoolean(self.api.config_set_bool(self.config, key, val and ffi.C.True or ffi.C.False))
      else
        local value = ffi.new('Bool[1]', 0)
        local ret = toBoolean(self.api.config_get_bool(self.config, key, value))
        if ret then return toBoolean(value[0]) end
      end
    end,
    int = function(self, key, val)
      if val then
        return toBoolean(self.api.config_set_int(self.config, key, tonumber(val)))
      else
        local value = ffi.new('int[1]', 0)
        local ret = toBoolean(self.api.config_get_int(self.config, key, value))
        if ret then return tonumber(value[0]) end
      end
    end,
    double = function(self, key, val)
      if val then
        return toBoolean(self.api.config_set_double(self.config, key, tonumber(val)))
      else
        local value = ffi.new('double[1]', 0)
        local ret = toBoolean(self.api.config_get_double(self.config, key, value))
        if ret then return tonumber(value[0]) end
      end
    end,
    string = function(self, key, val)
      if val then
        return toBoolean(self.api.config_set_string(self.config, key, val))
      else
        local value = ffi.new('char[1024]', 0)
        local ret = toBoolean(self.api.config_get_string(self.config, key, value, ffi.sizeof(value) - 1))
        if ret then return toString(value) end
      end
    end,
    item = function(self, key, val)
      if val then
        return toBoolean(self.api.config_set_item(self.config, key, val))
      else
        local value = StructCreate('RimeConfig[1]', gc_config)
        local ret = toBoolean(self.api.config_get_item(self.config, key, value))
        if ret then
          return setmetatable({
            config = value,
            api = self.api,
          }, mtRimeConfig)
        end
      end
    end,
    updateSignature = function(self, signer)
      return toBoolean(self.api.config_update_signature(self.config, signer))
    end,
    close = function(self)
      return toBoolean(self.api.config_close(self.config))
    end,
    clear = function(self, key)
      return toBoolean(self.api.config_clear(self.config, key))
    end,
    size = function(self, key)
      return tonumber(self.api.config_list_size(self.config, key))
    end,
    create_list = function(self, key)
      return toBoolean(self.api.config_create_list(self.config, key))
    end,
    create_map = function(self, key)
      return toBoolean(self.api.config_create_map(self.config, key))
    end,
    iterator = function(self, key)
      local iter = StructCreate('RimeConfigIterator[1]', function(iter)
        self.api.config_end(iter)
      end)

      local size = tonumber(self.api.config_list_size(self.config, key))
      local ret = nil
      if size == 0 then
        ret = toBoolean(self.api.config_begin_map(iter, self.config, key))
      else
        ret = toBoolean(self.api.config_begin_list(iter, self.config, key))
      end

      if ret then
        local iterator = { iterator = iter }
        local function next(_, _iter)
          local b = toBoolean(self.api.config_next(_iter.iterator))
          if b then
            _iter.path = ffi.string(_iter.iterator[0].path)
            if size == 0 then
              _iter.key = ffi.string(_iter.iterator[0].key)
            else
              _iter.index = tonumber(_iter.iterator[0].index)
            end
            return _iter
          else
            _iter = nil
          end
        end
        return next, self, iterator
      end
    end
  },
  __gc = function(self)
    self.api.config_close(self.config)
  end
}

-- session -------------------------------------------------------------------
-- menu help
local function Menu(menu)
  local ret = {}
  ret.page_size = menu.page_size
  ret.page_no = menu.page_no
  ret.is_last_page = toBoolean(menu.is_last_page)
  ret.highlighted_candidate_index = menu.highlighted_candidate_index + 1

  ret.num_candidates = menu.num_candidates
  local candidates = {}
  for i = 0, ret.num_candidates - 1 do
    table.insert(candidates, {
      text = toString(menu.candidates[i].text),
      comment = toString(menu.candidates[i].comment)
    })
  end
  ret.candidates = candidates

  if not IsNULL(menu.select_keys) then
    ret.select_keys = ffi.string(menu.select_keys)
  end
  return ret
end

-- composition help
local function Composition(composition)
  local ret = {}
  ret.length = composition.length;
  ret.cursor = composition.cursor_pos + 1
  ret.sel_start = composition.sel_start + 1
  ret.sel_end = composition.sel_end
  ret.preedit = composition.length > 0 and ffi.string(composition.preedit, ret.length) or nil
  return ret
end

-- session metatable
local mtSession = {
  __index = {
    exist = function(self)
      return toBoolean(self.api.find_session(self.id))
    end,
    destroy = function(self)
      if self.destroyed then
        return true
      end
      if toBoolean(self.api.find_session(self.id)) then
        self.destroyed = toBoolean(self.api.destroy_session(self.id))
      else
        self.destroyed = true
      end
      return self.destroyed
    end,
    -- testing -------------------------------------------------------------------
    simulate = function(self, key_sequence)
      return toBoolean(self.api.simulate_key_sequence(self.id, key_sequence))
    end,
    --input
    process = function(self, keycode, mask)
      mask = mask or 0
      return toBoolean(self.api.process_key(self.id, keycode, mask))
    end,
    --return True if there is unread commit text
    commit = function(self)
      return toBoolean(self.api.commit_composition(self.id))
    end,
    clear = function(self)
      self.host.clear_composition(self.id)
    end,

    --output
    Commit = function(self)
      local commit = StructCreateInit('RimeCommit[1]')
      if toBoolean(self.api.get_commit(self.id, commit)) then
        return ffi.string(commit[0].text)
      end
    end,

    Status = function(self)
      local function totable(status)
        local ret      = {}
        ret.id         = ffi.string(status.schema_id)
        ret.name       = ffi.string(status.schema_name)

        ret.disabled   = toBoolean(status.is_disabled)
        ret.composing  = toBoolean(status.is_composing)
        ret.ascii_mode = toBoolean(status.is_ascii_mode)
        ret.full_shape = toBoolean(status.is_full_shape)
        ret.simplified = toBoolean(status.is_simplified)
        ret.traditional = toBoolean(status.is_traditional)
        ret.ascii_punct = toBoolean(status.is_ascii_punct)

        return ret
      end

      local status = StructCreateInit('RimeStatus[1]', function(status)
        self.api.free_status(status);
      end)

      if toBoolean(self.api.get_status(self.id, status)) then
        return totable(status[0])
      end
    end,

    Context = function(self)
      local context = StructCreateInit('RimeContext[1]')
      if toBoolean(self.api.get_context(self.id, context)) then
        local ret = {
          composition = Composition(context[0].composition),
          menu = Menu(context[0].menu),
        }

        if not IsNULL(context[0].select_labels) then
          local lables = {}
          local i = 0
          repeat
            local l = context[0].select_labels[i]
            if not IsNULL(l) then
              lables[#lables + 1] = ffi.string(l)
            end
          until IsNULL(l)
          ret.select_labels = lables
        end

        if not IsNULL(context[0].commit_text_preview) then
          ret.commit_text_preview = ffi.string(context[0].commit_text_preview)
        end

        self.api.free_context(context)
        return ret
      end
    end,
    ------------------------------------------------------------------------------
    --runtime
    Option = function(self, option, value)
      if value == nil then
        return toBoolean(self.api.get_option(self.id, option))
      else
        self.api.set_option(self.id, option, toBool(value))
      end
    end,

    Property = function(self, prop, value)
      if value == nil then
        local val = ffi.new('char[1024]', 0)
        local ret = toBoolean(self.api.get_property(self.id, prop, val, ffi.sizeof(val) - 1))
        if ret then
          return toString(val)
        end
        return nil
      else
        assert(type(value) == 'string')
        self.api.set_property(self.id, prop, value)
      end
    end,

    Schema = function(self, schema_id)
      if schema_id == nil then
        local current = ffi.new('char[256]', 0)
        if toBoolean(self.api.get_current_schema(self.id, current, ffi.sizeof(current) - 1)) then
          return ffi.string(current);
        end
      else
        return toBoolean(self.api.select_schema(self.id, schema_id))
      end
    end,

    ------------------------------------------------------------------------------
    --! get raw input
    --[[!
      *  NULL is returned if session does not exist.
      *  the returned pointer to input string will become invalid upon editing.
    --]]
    Input = function(self)
      return toString(self.api.get_input(self.id))
    end,

    --! if pos==nil, get caret posistion in terms of raw input
    --! or set caret posistion in terms of raw input
    CaretPos = function(self, pos)
      if pos == nil then
        return tonumber(self.api.get_caret_pos(self.id)) + 1
      else
        assert(pos > 0)
        self.api.set_caret_pos(self.id, pos - 1);
      end
    end,

    --! if full is true, select a candidate at the given index in candidate list.
    --! or select a candidate from current page.
    Select = function(self, index, full)
      assert(index > 0)
      if full then
        return toBoolean(self.api.select_candidate(self.id, index - 1))
      else
        return toBoolean(self.api.select_candidate_on_current_page(self.id, index - 1))
      end
    end,

    --! access candidate list.
    Candidates = function(self)
      local iterator = StructCreate('RimeCandidateListIterator[1]', function(iter)
        self.api.candidate_list_end(iter)
      end)

      local lists = {}
      local b = self.api.candidate_list_begin(self.id, iterator)
      if toBoolean(b) then
        repeat
          local more = toBoolean(self.api.candidate_list_next(iterator))
          if more then
            lists[iterator[0].index + 1] = {
              text = toString(iterator[0].candidate.text),
              comment = toString(iterator[0].candidate.comment)
            }
          end
        until not more
      end
      return lists
    end,
  },
  __gc = function(self)
    if self.destroyed then
      return true
    end
    if toBoolean(self.api.find_session(self.id)) then
      self.destroyed = toBoolean(self.api.destroy_session(self.id))
    else
      self.destroyed = true
    end
    return self.destroyed
  end
}


-- initialize ----------------------------------------------------------------
local function toTraits(self, datadir, userdir, distname, appname, appver)
  _                                = self
  datadir                          = datadir or 'data'
  userdir                          = userdir or 'data'
  distname                         = distname or 'LRime'
  appname                          = appname or 'LuaRime'
  appver                           = appver or '0.01'

  local traits                     = StructCreateInit('RimeTraits[1]')
  traits[0].shared_data_dir        = datadir
  traits[0].user_data_dir          = userdir
  traits[0].distribution_name      = distname
  traits[0].distribution_code_name = appname
  traits[0].distribution_version   = appver
  traits[0].app_name               = appname .. ' ' .. appver
  traits[0].min_log_level          = 3

  return traits
end
------------------------------------------------------------------------------
local function printf(...)
  io.write(string.format(...))
end
local function fprintf(file, ...)
  file:write(string.format(...));
end
local function putchar(...)
  io.write(...);
end

local utils = {}

local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

function utils.print_r(root)
  if type(root) ~= 'table' then
    print(root)
    return
  end
  local cache = { [root] = "." }
  local function _dump(t, space, name)
    local temp = {}
    for k, v in pairs(t) do
      local key = tostring(k)
      if cache[v] then
        tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
      elseif type(v) == "table" then
        local new_key = name .. "." .. key
        cache[v] = new_key
        tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
      else
        tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
      end
    end
    return tconcat(temp, "\n" .. space)
  end
  print(_dump(root, "", ""))
end

function utils.printStatus(status)
  if not status then return end

  print(string.format("schema: %s / %s", status.id, status.name))
  print("status: ");
  print('   disabled:', status.disabled)
  print('  composing:', status.composing)
  print(' ascii_mode:', status.ascii_mode)
  print(' full_shape:', status.full_shape)
  print(' simplified:', status.simplified)
  print("");
end

function utils.printComposition(composition)
  if not composition then return end

  local preedit = composition.preedit;
  if not preedit then return end

  local start = composition.sel_start;
  local endf = composition.sel_end;
  local cursor = composition.cursor;
  local len = #preedit
  if start < endf then
    printf(preedit:sub(1, start - 1))
    printf('[')
    printf(preedit:sub(start, endf))
    printf(']')
    printf(preedit:sub(endf + 1, len))
    print();
    printf(' ')
    printf(string.rep('-', cursor - 1))
    printf('^')
    printf(' ')
    print()
  end
end

function utils.printMenu(menu, composition)
  if not menu then return end
  if (menu.num_candidates == 0) then return end

  printf("page: %d%s (of size %d)\n",
    menu.page_no + 1,
    menu.is_last_page and '$' or ' ',
    menu.page_size);
  for i = 1, menu.num_candidates do
    local highlighted = i == menu.highlighted_candidate_index
    printf("%d. %s%s%s%s\n",
      i,
      highlighted and '[' or ' ',
      menu.candidates[i].text,
      highlighted and ']' or ' ',
      menu.candidates[i].comment and composition.candidates[i].comment or ""
    )
  end
end

function utils.printContext(context)
  if not context then
    print('context is nil')
    return
  end

  if context.composition then
    utils.printComposition(context.composition)
    utils.printMenu(context.menu, context.composition)
  else
    print("(not composing)");
  end
end

function utils.printInfo(session, commit)
  if not session then return end
  commit = commit and session:Commit()
  if commit then
    printf("commit: %s\n", commit)
    print()
  end

  local status = session:Status()
  if (status) then
    print('----Status----')
    utils.printStatus(status);
    print()
  end

  local context = session:Context()
  if context then
    print('----context----')
    utils.printContext(context)
    print()
  end
end

-- IME
-- IME libs
local rime
_G.initialized = nil

-- IME metatable
local mtIME = {
  __index = {
    -- help
    toTraits = toTraits,
    -- setup
    setup = function(self, traits)
      assert(_G.initialized == nil)
      assert(traits)
      self.api.setup(traits)
      _G.initialized = true
    end,
    -- initialize
    initialize = function(self, traits, fullcheck, on_message)
      assert(self.initlized == nil)
      local api = self.api
      fullcheck = fullcheck or ffi.C.False
      assert(traits)

      if not _G.initialized then
        self:setup(traits)
      end

      if not self.initlized then
        on_message = on_message or function(context_object, session_id, message_type, message_value)
          _ = context_object
          local msg = string.format("message: [%d] [%s] %s\n",
            tonumber(session_id),
            toString(message_type),
            toString(message_value))
          print(msg)
        end
        --WARNING: on_message is not thread-safe, Lua not support threads
        --api.set_notification_handler(on_message, nil);

        api.initialize(traits);
        if (self.api.start_maintenance(fullcheck)) then
          api.join_maintenance_thread();
        end
      end
      self.initlized = true
      return self.initlized
    end,

    finalize = function(self)
      assert(self.initlized)
      self.api.finalize()
      self.initlized = nil
    end,

    start_maintenance = function(self, full_check)
      return toBoolean(self.api.start_maintenance(toBool(full_check)))
    end,
    is_maintenance_mode = function(self)
      return toBoolean(self.api.is_maintenance_mode())
    end,
    join_maintenance_thread = function(self)
      self.api.join_maintenance_thread()
    end,

    --deployment
    deployer_initialize = function(self, traits)
      self.api.deployer_initialize(traits)
    end,
    prebuild = function(self)
      return toBoolean(self.api.prebuild())
    end,
    deploy = function(self)
      return toBoolean(self.api.deploy())
    end,
    deploy_schema = function(self, schema_file)
      return toBoolean(self.api.deploy_schema(schema_file))
    end,

    deploy_config_file = function(self, file_name, version_key)
      return toBoolean(self.api.deploy_config_file(file_name, version_key))
    end,
    sync_user_data = function(self)
      return toBoolean(self.api.sync_user_data())
    end,

    --get all schema support
    Schemas = function(self)
      local api = self.api
      local schemas = StructCreate('RimeSchemaList[1]', function(schemas)
        api.free_schema_list(schemas)
      end)

      if toBoolean(self.api.get_schema_list(schemas)) then
        local ret = {}
        for i = 0, tonumber(schemas[0].size) - 1 do
          ret[#ret + 1] = {
            id = ffi.string(schemas[0].list[i].schema_id),
            name = ffi.string(schemas[0].list[i].name)
          }
        end
        return ret
      end
    end,
    --session management
    SessionCreate = function(self)
      local id = self.api.create_session()
      if id ~= 0 then
        return setmetatable({ id = id, api = self.api }, mtSession)
      end
    end,
    SessionCleanup = function(self, all)
      if not all then
        self.api.cleanup_stale_sessions()
      else
        self.api.cleanup_all_sessions()
      end
    end,

    -- rime config ---------------------------------------------------------------
    --! get the version of librime
    Version = function(self)
      return toString(self.api.get_version())
    end,
    SharedDataDir = function(self)
      return toString(self.api.get_shared_data_dir())
    end,
    UserDataDir = function(self)
      return toString(self.api.get_user_data_dir())
    end,
    SyncDir = function(self)
      return toString(self.api.get_sync_dir())
    end,
    UserId = function(self)
      return toString(self.api.get_user_id())
    end,
    UserDataSyncDir = function(self)
      local buff = ffi.new('char[256]', 0)
      return toString(self.api.get_user_data_sync_dir(buff, ffi.sizeof(buff) - 1))
    end,

    --config
    ConfigCreate = function(self, init)
      local config = ffi.new('RimeConfig[1]')
      if init then
        local ret = toBoolean(self.api.config_init(config))
        if not ret then
          return nil
        end
      end
      return setmetatable({
        config = config,
        api = self.api,
      }, mtRimeConfig)
    end,

    ConfigOpen = function(self, config_id)
      local config = ffi.new('RimeConfig[1]')
      local ret = toBoolean(self.api.config_open(config_id, config))

      if ret then
        return setmetatable({
          config = config,
          api = self.api,
        }, mtRimeConfig)
      end
    end,

    SchemaOpen = function(self, schema_id)
      local config = ffi.new('RimeConfig[1]')
      local ret = toBoolean(self.api.schema_open(schema_id, config))
      if ret then
        return setmetatable({
          config = config,
          api = self.api,
        }, mtRimeConfig)
      end
    end,
    --
    utils = utils
  },

  __call = function(self, sopath)
    if not sopath then
      sopath = ffi.os == 'Windows' and 'rime.dll' or 'librime.so'
    end

    if rime == nil then
      local debug = require 'debug'
      local path = debug.getinfo(1).source --  @e:\work\luaapps\PBOC\lib\HSM\Driver.lua
      if ffi.os == 'Windows' then
        path = string.sub(path, 2, -1)
        path = string.gsub(path, "\\", '/')
      elseif ffi.os == 'OSX' then
        path = string.sub(path, 2, -1)
      end

      --get folder of path
      local off, e = 1, nil
      repeat
        e = string.find(path, '/', off + 1, true)
        if e then off = e end
      until e == nil
      path = path:sub(1, off) or './'

      local f = assert(io.open(path .. 'rime.h'))
      local ctx = f:read('*a')
      f:close()
      ffi.cdef(ctx)
      rime = ffi.load(sopath)
    end

    self.api = rime.rime_get_api()
    return self
  end,

  __gc = function(self)
    print("RimeFinalize")
    rime.RimeFinalize()
  end
}

------------------------------------------------------------------------------

return setmetatable({}, mtIME)
