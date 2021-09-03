# xnatapic

xnatapic stands for XNAT API Client. Fancy isn't it? It groups a set of API calls to XNAT platform written in Bash. General idea here is:

 - Easy to use
 - Easy to extend
 - Just a few dependencies
 - As fast as possible

### Dependencies

 -  curl
 - jq

### Install

Just copy the main bash script (bin/xnatapic) to a place where it can be found and executed (/usr/local/bin/ ?) and the operational scripts (share/\*.sh) to a place where they can be found by the main script (/usr/local/share/xnatapic/ ?).

Now you should configure the user access. Copy the file _share/xnat.conf_ to _$HOME/.xnatapic/xnat.conf_, edit it and change _URL_, _user_ and _password_ for your XNAT user data.

### Extending it

You can create your own API call procedure by taking any of the existing ones as a template and placing it at _$HOME/.xnatapic/_ with a different name.


