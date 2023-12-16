typedef uintptr_t RimeSessionId;
typedef int Bool;

enum {
  False = 0,
  True = 1
};

//! Rime traits structure
/*!
 *  Should be initialized by calling RIME_STRUCT_INIT(Type, var)
 */
typedef struct rime_traits_t {
  int data_size;
  // v0.9
  const char* shared_data_dir;
  const char* user_data_dir;
  const char* distribution_name;
  const char* distribution_code_name;
  const char* distribution_version;
  // v1.0
  /*!
   * Pass a C-string constant in the format "rime.x"
   * where 'x' is the name of your application.
   * Add prefix "rime." to ensure old log files are automatically cleaned.
   */
  const char* app_name;

  //! A list of modules to load before initializing
  const char** modules;
  // v1.6
  /*! Minimal level of logged messages.
   *  Value is passed to Glog library using FLAGS_minloglevel variable.
   *  0 = INFO (default), 1 = WARNING, 2 = ERROR, 3 = FATAL
   */
  int min_log_level;
  /*! Directory of log files.
   *  Value is passed to Glog library using FLAGS_log_dir variable.
   */
  const char* log_dir;
  //! prebuilt data directory. defaults to ${shared_data_dir}/build
  const char* prebuilt_data_dir;
  //! staging directory. defaults to ${user_data_dir}/build
  const char* staging_dir;
} RimeTraits;

typedef struct {
  int length;
  int cursor_pos;
  int sel_start;
  int sel_end;
  char* preedit;
} RimeComposition;

typedef struct rime_candidate_t {
  char* text;
  char* comment;
  void* reserved;
} RimeCandidate;

typedef struct {
  int page_size;
  int page_no;
  Bool is_last_page;
  int highlighted_candidate_index;
  int num_candidates;
  RimeCandidate* candidates;
  char* select_keys;
} RimeMenu;

/*!
 *  Should be initialized by calling RIME_STRUCT_INIT(Type, var);
 */
typedef struct rime_commit_t {
  int data_size;
  // v0.9
  char* text;
} RimeCommit;

/*!
 *  Should be initialized by calling RIME_STRUCT_INIT(Type, var);
 */
typedef struct rime_context_t {
  int data_size;
  // v0.9
  RimeComposition composition;
  RimeMenu menu;
  // v0.9.2
  char* commit_text_preview;
  char** select_labels;
} RimeContext;

/*!
 *  Should be initialized by calling RIME_STRUCT_INIT(Type, var);
 */
typedef struct rime_status_t {
  int data_size;
  // v0.9
  char* schema_id;
  char* schema_name;
  Bool is_disabled;
  Bool is_composing;
  Bool is_ascii_mode;
  Bool is_full_shape;
  Bool is_simplified;
  Bool is_traditional;
  Bool is_ascii_punct;
} RimeStatus;

typedef struct rime_candidate_list_iterator_t {
  void *ptr;
  int index;
  RimeCandidate candidate;
} RimeCandidateListIterator;

typedef struct rime_config_t {
  void* ptr;
} RimeConfig;

typedef struct rime_config_iterator_t {
  void* list;
  void* map;
  int index;
  const char* key;
  const char* path;
} RimeConfigIterator;

typedef struct rime_schema_list_item_t {
  char* schema_id;
  char* name;
  void* reserved;
} RimeSchemaListItem;

typedef struct rime_schema_list_t {
  size_t size;
  RimeSchemaListItem* list;
} RimeSchemaList;

typedef void (*RimeNotificationHandler)(void* context_object,
                                        RimeSessionId session_id,
                                        const char* message_type,
                                        const char* message_value);

typedef struct rime_string_slice_t {
  const char* str;
  size_t length;
} RimeStringSlice;

// Setup

/*!
 *  Call this function before accessing any other API.
 */
void RimeSetup(RimeTraits *traits);

/*!
 *  Pass a C-string constant in the format "rime.x"
 *  where 'x' is the name of your application.
 *  Add prefix "rime." to ensure old log files are automatically cleaned.
 *  \deprecated Use RimeSetup() instead.
 */
void RimeSetupLogging(const char* app_name);

//! Receive notifications
/*!
 * - on loading schema:
 *   + message_type="schema", message_value="luna_pinyin/Luna Pinyin"
 * - on changing mode:
 *   + message_type="option", message_value="ascii_mode"
 *   + message_type="option", message_value="!ascii_mode"
 * - on deployment:
 *   + session_id = 0, message_type="deploy", message_value="start"
 *   + session_id = 0, message_type="deploy", message_value="success"
 *   + session_id = 0, message_type="deploy", message_value="failure"
 *
 *   handler will be called with context_object as the first parameter
 *   every time an event occurs in librime, until RimeFinalize() is called.
 *   when handler is NULL, notification is disabled.
 */
void RimeSetNotificationHandler(RimeNotificationHandler handler,
                                         void* context_object);

// Entry and exit

void RimeInitialize(RimeTraits *traits);
void RimeFinalize();

Bool RimeStartMaintenance(Bool full_check);

//! \deprecated Use RimeStartMaintenance(full_check = False) instead.
Bool RimeStartMaintenanceOnWorkspaceChange();
Bool RimeIsMaintenancing();
void RimeJoinMaintenanceThread();

// Deployment

void RimeDeployerInitialize(RimeTraits *traits);
Bool RimePrebuildAllSchemas();
Bool RimeDeployWorkspace();
Bool RimeDeploySchema(const char *schema_file);
Bool RimeDeployConfigFile(const char *file_name, const char *version_key);

Bool RimeSyncUserData();

// Session management

RimeSessionId RimeCreateSession();
Bool RimeFindSession(RimeSessionId session_id);
Bool RimeDestroySession(RimeSessionId session_id);
void RimeCleanupStaleSessions();
void RimeCleanupAllSessions();

// Input

Bool RimeProcessKey(RimeSessionId session_id, int keycode, int mask);
/*!
 * return True if there is unread commit text
 */
Bool RimeCommitComposition(RimeSessionId session_id);
void RimeClearComposition(RimeSessionId session_id);

// Output

Bool RimeGetCommit(RimeSessionId session_id, RimeCommit* commit);
Bool RimeFreeCommit(RimeCommit* commit);
Bool RimeGetContext(RimeSessionId session_id, RimeContext* context);
Bool RimeFreeContext(RimeContext* context);
Bool RimeGetStatus(RimeSessionId session_id, RimeStatus* status);
Bool RimeFreeStatus(RimeStatus* status);

// Accessing candidate list

Bool RimeCandidateListBegin(RimeSessionId session_id, RimeCandidateListIterator* iterator);
Bool RimeCandidateListNext(RimeCandidateListIterator* iterator);
void RimeCandidateListEnd(RimeCandidateListIterator* iterator);

// Runtime options

void RimeSetOption(RimeSessionId session_id, const char* option, Bool value);
Bool RimeGetOption(RimeSessionId session_id, const char* option);

void RimeSetProperty(RimeSessionId session_id, const char* prop, const char* value);
Bool RimeGetProperty(RimeSessionId session_id, const char* prop, char* value, size_t buffer_size);

Bool RimeGetSchemaList(RimeSchemaList* schema_list);
void RimeFreeSchemaList(RimeSchemaList* schema_list);
Bool RimeGetCurrentSchema(RimeSessionId session_id, char* schema_id, size_t buffer_size);
Bool RimeSelectSchema(RimeSessionId session_id, const char* schema_id);

// Configuration

// <schema_id>.schema.yaml
Bool RimeSchemaOpen(const char* schema_id, RimeConfig* config);
// <config_id>.yaml
Bool RimeConfigOpen(const char* config_id, RimeConfig* config);
Bool RimeConfigClose(RimeConfig* config);
Bool RimeConfigInit(RimeConfig* config);
Bool RimeConfigLoadString(RimeConfig* config, const char* yaml);
// Access config values
Bool RimeConfigGetBool(RimeConfig *config, const char *key, Bool *value);
Bool RimeConfigGetInt(RimeConfig *config, const char *key, int *value);
Bool RimeConfigGetDouble(RimeConfig *config, const char *key, double *value);
Bool RimeConfigGetString(RimeConfig *config, const char *key,
                                  char *value, size_t buffer_size);
const char* RimeConfigGetCString(RimeConfig *config, const char *key);
Bool RimeConfigSetBool(RimeConfig *config, const char *key, Bool value);
Bool RimeConfigSetInt(RimeConfig *config, const char *key, int value);
Bool RimeConfigSetDouble(RimeConfig *config, const char *key, double value);
Bool RimeConfigSetString(RimeConfig *config, const char *key, const char *value);
// Manipulate complex structures
Bool RimeConfigGetItem(RimeConfig* config, const char* key, RimeConfig* value);
Bool RimeConfigSetItem(RimeConfig* config, const char* key, RimeConfig* value);
Bool RimeConfigClear(RimeConfig* config, const char* key);
Bool RimeConfigCreateList(RimeConfig* config, const char* key);
Bool RimeConfigCreateMap(RimeConfig* config, const char* key);
size_t RimeConfigListSize(RimeConfig* config, const char* key);
Bool RimeConfigBeginList(RimeConfigIterator* iterator, RimeConfig* config, const char* key);
Bool RimeConfigBeginMap(RimeConfigIterator* iterator, RimeConfig* config, const char* key);
Bool RimeConfigNext(RimeConfigIterator* iterator);
void RimeConfigEnd(RimeConfigIterator* iterator);
// Utilities
Bool RimeConfigUpdateSignature(RimeConfig* config, const char* signer);

// Testing

Bool RimeSimulateKeySequence(RimeSessionId session_id, const char *key_sequence);

// Module

/*!
 *  Extend the structure to publish custom data/functions in your specific module
 */
typedef struct rime_custom_api_t {
  int data_size;
} RimeCustomApi;

typedef struct rime_module_t {
  int data_size;

  const char* module_name;
  void (*initialize)();
  void (*finalize)();
  RimeCustomApi* (*get_api)();
} RimeModule;

Bool RimeRegisterModule(RimeModule* module);
RimeModule* RimeFindModule(const char* module_name);

//! Run a registered task
Bool RimeRunTask(const char* task_name);

const char* RimeGetSharedDataDir();
const char* RimeGetUserDataDir();
const char* RimeGetSyncDir();
const char* RimeGetUserId();

/*! The API structure
 *  RimeApi is for rime v1.0+
 */
typedef struct rime_api_t {
  int data_size;

  /*! setup
   *  Call this function before accessing any other API functions.
   */
  void (*setup)(RimeTraits* traits);

  /*! Set up the notification callbacks
   *  Receive notifications
   *  - on loading schema:
   *    + message_type="schema", message_value="luna_pinyin/Luna Pinyin"
   *  - on changing mode:
   *    + message_type="option", message_value="ascii_mode"
   *    + message_type="option", message_value="!ascii_mode"
   *  - on deployment:
   *    + session_id = 0, message_type="deploy", message_value="start"
   *    + session_id = 0, message_type="deploy", message_value="success"
   *    + session_id = 0, message_type="deploy", message_value="failure"
   *
   *  handler will be called with context_object as the first parameter
   *  every time an event occurs in librime, until RimeFinalize() is called.
   *  when handler is NULL, notification is disabled.
   */
  void (*set_notification_handler)(RimeNotificationHandler handler,
                                   void* context_object);

  // entry and exit

  void (*initialize)(RimeTraits *traits);
  void (*finalize)();

  Bool (*start_maintenance)(Bool full_check);
  Bool (*is_maintenance_mode)();
  void (*join_maintenance_thread)();

  // deployment

  void (*deployer_initialize)(RimeTraits *traits);
  Bool (*prebuild)();
  Bool (*deploy)();
  Bool (*deploy_schema)(const char *schema_file);
  Bool (*deploy_config_file)(const char *file_name, const char *version_key);

  Bool (*sync_user_data)();

  // session management

  RimeSessionId (*create_session)();
  Bool (*find_session)(RimeSessionId session_id);
  Bool (*destroy_session)(RimeSessionId session_id);
  void (*cleanup_stale_sessions)();
  void (*cleanup_all_sessions)();

  // input

  Bool (*process_key)(RimeSessionId session_id, int keycode, int mask);
  // return True if there is unread commit text
  Bool (*commit_composition)(RimeSessionId session_id);
  void (*clear_composition)(RimeSessionId session_id);

  // output

  Bool (*get_commit)(RimeSessionId session_id, RimeCommit* commit);
  Bool (*free_commit)(RimeCommit* commit);
  Bool (*get_context)(RimeSessionId session_id, RimeContext* context);
  Bool (*free_context)(RimeContext* ctx);
  Bool (*get_status)(RimeSessionId session_id, RimeStatus* status);
  Bool (*free_status)(RimeStatus* status);

  // runtime options

  void (*set_option)(RimeSessionId session_id, const char* option, Bool value);
  Bool (*get_option)(RimeSessionId session_id, const char* option);

  void (*set_property)(RimeSessionId session_id, const char* prop, const char* value);
  Bool (*get_property)(RimeSessionId session_id, const char* prop, char* value, size_t buffer_size);

  Bool (*get_schema_list)(RimeSchemaList* schema_list);
  void (*free_schema_list)(RimeSchemaList* schema_list);

  Bool (*get_current_schema)(RimeSessionId session_id, char* schema_id, size_t buffer_size);
  Bool (*select_schema)(RimeSessionId session_id, const char* schema_id);

  // configuration

  Bool (*schema_open)(const char *schema_id, RimeConfig* config);
  Bool (*config_open)(const char *config_id, RimeConfig* config);
  Bool (*config_close)(RimeConfig *config);
  Bool (*config_get_bool)(RimeConfig *config, const char *key, Bool *value);
  Bool (*config_get_int)(RimeConfig *config, const char *key, int *value);
  Bool (*config_get_double)(RimeConfig *config, const char *key, double *value);
  Bool (*config_get_string)(RimeConfig *config, const char *key,
                            char *value, size_t buffer_size);
  const char* (*config_get_cstring)(RimeConfig *config, const char *key);
  Bool (*config_update_signature)(RimeConfig* config, const char* signer);
  Bool (*config_begin_map)(RimeConfigIterator* iterator, RimeConfig* config, const char* key);
  Bool (*config_next)(RimeConfigIterator* iterator);
  void (*config_end)(RimeConfigIterator* iterator);

  // testing

  Bool (*simulate_key_sequence)(RimeSessionId session_id, const char *key_sequence);

  // module

  Bool (*register_module)(RimeModule* module);
  RimeModule* (*find_module)(const char* module_name);

  Bool (*run_task)(const char* task_name);
  const char* (*get_shared_data_dir)();
  const char* (*get_user_data_dir)();
  const char* (*get_sync_dir)();
  const char* (*get_user_id)();
  void (*get_user_data_sync_dir)(char* dir, size_t buffer_size);

  //! initialize an empty config object
  /*!
   * should call config_close() to free the object
   */
  Bool (*config_init)(RimeConfig* config);
  //! deserialize config from a yaml string
  Bool (*config_load_string)(RimeConfig* config, const char* yaml);

  // configuration: setters
  Bool (*config_set_bool)(RimeConfig *config, const char *key, Bool value);
  Bool (*config_set_int)(RimeConfig *config, const char *key, int value);
  Bool (*config_set_double)(RimeConfig *config, const char *key, double value);
  Bool (*config_set_string)(RimeConfig *config, const char *key, const char *value);

  // configuration: manipulating complex structures
  Bool (*config_get_item)(RimeConfig* config, const char* key, RimeConfig* value);
  Bool (*config_set_item)(RimeConfig* config, const char* key, RimeConfig* value);
  Bool (*config_clear)(RimeConfig* config, const char* key);
  Bool (*config_create_list)(RimeConfig* config, const char* key);
  Bool (*config_create_map)(RimeConfig* config, const char* key);
  size_t (*config_list_size)(RimeConfig* config, const char* key);
  Bool (*config_begin_list)(RimeConfigIterator* iterator, RimeConfig* config, const char* key);

  //! get raw input
  /*!
   *  NULL is returned if session does not exist.
   *  the returned pointer to input string will become invalid upon editing.
   */
  const char* (*get_input)(RimeSessionId session_id);

  //! caret posistion in terms of raw input
  size_t (*get_caret_pos)(RimeSessionId session_id);

  //! select a candidate at the given index in candidate list.
  Bool (*select_candidate)(RimeSessionId session_id, size_t index);

  //! get the version of librime
  const char* (*get_version)();

  //! set caret posistion in terms of raw input
  void (*set_caret_pos)(RimeSessionId session_id, size_t caret_pos);

  //! select a candidate from current page.
  Bool (*select_candidate_on_current_page)(RimeSessionId session_id, size_t index);

  // access candidate list.
  Bool (*candidate_list_begin)(RimeSessionId session_id, RimeCandidateListIterator* iterator);
  Bool (*candidate_list_next)(RimeCandidateListIterator* iterator);
  void (*candidate_list_end)(RimeCandidateListIterator* iterator);

  //! access config files in user data directory, eg. user.yaml and
  //! installation.yaml
  Bool (*user_config_open)(const char* config_id, RimeConfig* config);

  Bool (*candidate_list_from_index)(RimeSessionId session_id,
                                    RimeCandidateListIterator* iterator,
                                    int index);

  //! prebuilt data directory.
  const char* (*get_prebuilt_data_dir)(void);
  //! staging directory, stores data files deployed to a Rime client.
  const char* (*get_staging_dir)(void);

  //! Deprecated: for capnproto API, use "proto" module from librime-proto
  //! plugin.
  void (*commit_proto)(RimeSessionId session_id,
                       void* commit_builder);
  void (*context_proto)(RimeSessionId session_id,
                        void* context_builder);
  void (*status_proto)(RimeSessionId session_id,
                       void* status_builder);

  const char* (*get_state_label)(RimeSessionId session_id,
                                 const char* option_name,
                                 Bool state);

  //! delete a candidate at the given index in candidate list.
  Bool (*delete_candidate)(RimeSessionId session_id, size_t index);
  //! delete a candidate from current page.
  Bool (*delete_candidate_on_current_page)(RimeSessionId session_id,
                                           size_t index);

  RimeStringSlice (*get_state_label_abbreviated)(RimeSessionId session_id,
                                                 const char* option_name,
                                                 Bool state,
                                                 Bool abbreviated);
} RimeApi;

//! API entry
/*!
 *  Acquire the version controlled RimeApi structure.
 */
RimeApi* rime_get_api();
