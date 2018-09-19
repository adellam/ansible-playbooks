<?php
define("DB_NAME", "{{ wordpress_db_name }}");
define("DB_USER", "{{ wordpress_db_user }}");
define("DB_PASSWORD", "{{ wordpress_db_pwd }}");
define("DB_HOST", "{{ wordpress_db_host }}");
define("DB_CHARSET", "utf8");
define("DB_COLLATE", "");

{{ wordpress_salt.stdout }}

$table_prefix  = "{{ wordpress_db_table_prefix }}";
define("WPLANG", "{{ wordpress_lang }}");
define("WP_DEBUG", {{ wordpress_debug }});
{% if wordpress_env is defined %}
define("WP_ENV", "{{ wordpress_env  }}");
{% endif %}

if (!defined("ABSPATH"))
  define("ABSPATH", dirname(__FILE__) . "/");

require_once(ABSPATH . "wp-settings.php");
