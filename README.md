DeviceSetupScripts
==================

Scripts to setup a device automatically, using the hostname as the device name.

These scripts expect two arguments, and an optional third argument:

    create_device.[cmd|sh] <username> <password> "<fingerprint>" [<username suffix>]

Username and password are the username and password for the SpiderOak account. Fingerprint is the fingerprint located on the OMVA at Manage > Fingerprint. If you are using an environment where the authentication username might require a suffix (such as AD environments for SpiderOakBlue), you can set the suffix as the fourth argument.

This will attempt to create a device using the user credentials using the name of the computer as reported by `%COMPUTERNAME%` on Windows and `$HOST` on *nix.

In the event that you already have a device with an existing name, this script will pick up on the error and rename the old device to `$HOST-old-timestamp`.

Note for SpiderOak Blue Users
-----------------------------

If you're using this script in conjunction with authentication tokens, please note that the renaming will **not** work in conjunction with the Single-Use Only access restriction. It however *will* work correctly if users are not allowed access to the WebAPI.