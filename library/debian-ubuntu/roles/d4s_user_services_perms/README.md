Several different scenarios are covered.

1. One smartgears tomcat instance, installed inside the user's home
2. One or more tomcat instances, each instance installed inside its
   user's home
3. One service, not tomcat based, installed inside the user's home
4. One service, installed inside the user's home, not managed by other
   ansible playbooks (only the user is created)
5. ACLs are used if more than one user must be able to read/write some
   common directories or files. This works both with the gcore and the
   smartgears cases

Important note: the variable 'http_port(s)' needs to be defined earlier in the calling playbook.

What the role does:

- Installs the sudoers config that permits the user to restart the
service
- Installs the script that allows the user to start and stop the
service without using the full path
- Installs the README file that explains where the options files are
placed and how start/stop the service
- The default open files limits are increased
- Creates additional users if needed, and adds ACLS to allow them
  access shared directories
