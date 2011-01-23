                          My configuration for Awesome

   This distribution my configuration for [1]Awesome window manager.

   Home page for the Awesome configuration is at
   [2]http://solitudo.net/software/awesome/config/. The configuration is
   also listed at the [3]User Configuration Files page in [4]Awesome wiki.

   The configuration supports following features
     * Menu support using [5]awesome-freedesktop
          + freedesktop.org applications menu with icons
          + Debian menu
          + Awesome menu
               o Theme selection.
                    # List of themes is automatically populated from the
                      themes installed under ~/.config/awesome/themes.
                    # Symlink ~/.config/awesome/current_theme points to
                      the selected theme
          + System menu for lock screen, logout, reboot, and shutdown
     * Autostarting of programs under ~/.config/awesome/autostart
       directory. For example, you can populate this directory with
       symlinks to the real applications like /usr/bin/xscreensaver. See
       this sample of my ~/.config/awesome/autostart:
(03:48:36)(tj@ganga)(~/.config/awesome)$ ls -al ~/.config/awesome/autostart/
total 8
drwxr-xr-x 2 tj staff 4096 Jan 11 00:26 .
drwxr-xr-x 6 tj staff 4096 Jan 23 03:48 ..
lrwxrwxrwx 1 tj staff   18 Aug 24 10:13 evolution -> /usr/bin/evolution
lrwxrwxrwx 1 tj staff   16 Aug 24 10:13 firefox -> /usr/bin/firefox
lrwxrwxrwx 1 tj staff   17 Aug 24 10:13 gnome-do -> /usr/bin/gnome-do
lrwxrwxrwx 1 tj staff   23 Aug 24 10:13 gnome-terminal -> /usr/bin/gnome-termina
l
lrwxrwxrwx 1 tj staff   17 Sep 15 01:44 nautilus -> /usr/bin/nautilus
lrwxrwxrwx 1 tj staff   19 Sep 19 14:33 pulseaudio -> /usr/bin/pulseaudio
lrwxrwxrwx 1 tj staff   18 Sep  4 10:45 rhythmbox -> /usr/bin/rhythmbox
lrwxrwxrwx 1 tj users   28 Jan 11 00:26 tomboy.sh -> /home/staff/tj/bin/tomboy.s
h
lrwxrwxrwx 1 tj staff   21 Aug 24 10:13 xscreensaver -> /usr/bin/xscreensaver

     * Host-specified rc.$HOSTNAME.lua is loaded if found under
       ~/.config/awesome.
          + Allows e.g. host-specified widget configuration to be built
            easily without changes to the main rc.lua on each machine.
     * Wibox with the following features
          + Awesome menu
          + Tag selector
          + Command prompt
          + Window list
          + Systray support
          + Support for Delightful widgets
          + Layout display and selection
     * Default key bindings with some extras
          + Mod4 + x evaluate Lua code removed
          + Mod4 + t to toggle titlebar of a client
          + Mod4 + q to display client selection menu
          + Mod4 + Shift + Tab to switch to focus previous client
          + Mod4 + Insert to move floating window up
          + Mod4 + Home to move floating window down
          + Mod4 + Delete to move floating window left
          + Mod4 + End to move floating window right
          + Mod4 + PageUp to resize floating window bigger
          + Mod4 + PageDown to resize floating window smaller
     * Rules to run many applications in floating mode by default

                                  Dependencies

   The configuration requires following external dependencies
     * [6]LuaPosix

   The following dependencies are included as Git submodules
     * [7]Delightful
     * [8]Tuomas Jormola's Awesome themes

   Delightful in requires a few external dependencies and provides some
   dependencies as submodules. See the [9]Delightful README for more info.
   The distribution of the configuration comes with ready symlinks
   pointing to the Delightful dependencies so after downloading the
   submodules, no other actions are required to make the dependencies
   work.

                                  Downloading

   Themes can be downloaded by cloning the public Git repository at
   git://scm.solitudo.net/tj-awesome-config.git. Gitweb interface is
   available at
   [10]http://scm.solitudo.net/gitweb/public/tj-awesome-config.git.

                                  Installation

    1. $ mv ~/.config/awesome ~/.config/awesome-old
    2. $ git clone git://scm.solitudo.net/tj-awesome-config.git
       ~/.config/awesome
    3. $ cd ~/.config/awesome && git submodule init
    4. $ cd ~/.config/awesome && git submodule update
    5. $ cd ~/.config/awesome/submodules/delightful && git submodule init
    6. $ cd ~/.config/awesome/submodules/delightful && git submodule
       update
    7. $ cp ~/.config/awesome/rc.HOSTNAME.lua.sample
       ~/.config/awesome/rc.$HOSTNAME.lua
    8. $ vi ~/.config/awesome/rc.$HOSTNAME.lua

                            Copyright and licensing

   Copyright: © 2011 Tuomas Jormola [11]tj@solitudo.net
   [12]http://solitudo.net

   Licensed under the terms of the [13]GNU General Public License Version
   2.0.

References

   1. http://awesome.naquadah.org/
   2. http://solitudo.net/software/awesome/config/
   3. https://awesome.naquadah.org/wiki/User_Configuration_Files
   4. https://awesome.naquadah.org/wiki/
   5. https://github.com/terceiro/awesome-freedesktop
   6. http://luaforge.net/projects/luaposix/
   7. http://solitudo.net/software/awesome/delightful/
   8. http://solitudo.net/software/awesome/themes/
   9. http://solitudo.net/software/awesome/delightful/README/
  10. http://scm.solitudo.net/gitweb/public/tj-awesome-config.git
  11. mailto:tj@solitudo.net
  12. http://solitudo.net/
  13. http://www.gnu.org/licenses/gpl-2.0.html
