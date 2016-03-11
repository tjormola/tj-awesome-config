-- Configuration for Awesome 3.5
-- Copyright (C) 2011-2016 Tuomas Jormola <tj@solitudo.net>
--
-- Licensed under the terms of GNU General Public License Version 2.0.
--
-- Features (see README for more detailed descriptions):
--
--    - awesome-freedesktop based menus
--    - Symlink and XDG based autostarting of applications
--    - Additional host specific configuration
--    - Wibox with Delightful support
--    - Almost default key bindings
--    - Floating mode rules for many applications

local awful       = require("awful")
local beautiful   = require("beautiful")
local freedesktop = { utils = require('freedesktop.utils'), menu = require('freedesktop.menu') }
local debian      = { menu = require('debian.menu') }

local posix       = require('posix')

local print       = print

function tj_variables()
    terminal                   = 'gnome-terminal'
    freedesktop.utils.terminal = terminal
    tagnum                     = 4
    wibox_position             = 'top'
end

function resolve_symlink(file, level)
    if not level then
        level = -1
    end
    local file_stat = posix.stat(file)
    if level ~= 0 and file_stat and file_stat.type == 'link' then
        local readlink_output = awful.util.pread(string.format('readlink %s', file)):gsub('%s*$', '')
        return resolve_symlink(readlink_output, level - 1)
    end

    return file
end

function launch_command(command)
    local basename = command:gsub('^.*/', ''):gsub('%s+.*$', '')
    awful.util.spawn_with_shell(string.format('pgrep -u $USER -f "%s$" >/dev/null || (%s &)', basename, command))
end

function tj_autostart()
    local autostart_commands = {}

    -- Awesome autostart directory
    local autostart_dir = string.format('%s/autostart', awful.util.getdir('config'))
    local autostart_stat = posix.stat(autostart_dir)
    if autostart_stat and autostart_stat.type == 'directory' then
        local files = posix.dir(autostart_dir)
        if files then
            for _, file in pairs(files) do
                local full_file = resolve_symlink(string.format('%s/%s', autostart_dir, file), 1)
                local file_stat = posix.stat(full_file)
                if file_stat and file_stat.type == 'regular' then
                    autostart_commands[full_file] = full_file
                end
            end
        end
    end
    -- XDG autostart
    local xdg_autostart_dirs = { string.format('%s/.config/autostart', os.getenv('HOME')), '/etc/xdg/autostart' }
    for _, xdg_autostart_dir in pairs(xdg_autostart_dirs) do
        local xdg_autostart_stat = posix.stat(xdg_autostart_dir)
        if xdg_autostart_stat and xdg_autostart_stat.type == 'directory' then
            local xdg_autostart_dirs = posix.dir(xdg_autostart_dir)
            for _, xdg_autostart_name in pairs(xdg_autostart_dirs) do
                local xdg_autostart_file = string.format('%s/%s', xdg_autostart_dir, xdg_autostart_name)
                local xdg_autostart_file_stat = posix.stat(resolve_symlink(xdg_autostart_file))
                if xdg_autostart_file_stat and xdg_autostart_file_stat.type == 'regular' and xdg_autostart_name:find('\.desktop$') then
                    local section
                    local commands = {}
                    for line in io.lines(xdg_autostart_file) do
                        local new_section
                        line:gsub('^%[([^%]]+)%]$', function(a) new_section = a:lower() end)
                        if (not section and new_section) or (new_section and section and section ~= new_section) then
                            section = new_section
                            commands[section] = { condition = true }
                        end
                        local key, value
                        line:gsub('^([^%s=]+)%s*=%s*(.+)%s*$', function(a, b) key = a:lower() value = b end)
                        if section and key and key == 'exec' then
                            commands[section]['command'] = value:gsub('%%.', ''):gsub('%s+$', '')
                        elseif section and key and key == 'autostartcondition' then
                            local condition = false
                            local condition_method, condition_args
                            value:gsub('^([^%s]+)%s+(.+)$', function(a, b) condition_method = a:lower() condition_args = b end)
                            if condition_method and condition_args and condition_method == 'gsettings' then
                                local gsettings_output = awful.util.pread(string.format('gsettings get %s', condition_args)):gsub('%s*$', '')
                                condition = gsettings_output and gsettings_output == 'true'
                            elseif condition_method and condition_args and condition_method == 'gnome' then
                                local gconftool_output = awful.util.pread(string.format('gconftool --get %s', condition_args)):gsub('%s*$', '')
                                condtion = gconftool_output and gconftool_output == 'true'
                            elseif condition_method and condition_args and condition_method == 'gnome3' then -- ignore
                            else
                                print(string.format('[awesome] Unknown AutostartCondition method: %s', condition_method))
                            end
                            commands[section]['condition'] = condition
                        end
                    end
                    local try_sections = { 'desktop action tray', 'desktop entry' }
                    for _, try_section in pairs(try_sections) do
                        if commands[try_section] and commands[try_section]['command'] and commands[try_section]['condition'] then
                            autostart_commands[commands[try_section]['command']] = 1
                            break
                        end
                    end
                end
            end
        end
    end
    for command in pairs(autostart_commands) do
        launch_command(command)
    end
end

function tj_local_config()
    local hostname = awful.util.pread('hostname -s'):gsub('\n', '')
    local host_config_file = awful.util.getdir('config') .. '/rc.' .. hostname .. '.lua'
    if awful.util.file_readable(host_config_file) then
        local host_config_function, host_config_load_error
        host_config_function, host_config_load_error = loadfile(host_config_file)
        if not host_config_load_error then
            host_config_function()
        else
            print(string.format('[awesome] Failed to load %s: %s', host_config_file, host_config_load_error))
        end
    end
end

function choose_theme(theme)
    local config = awful.util.getdir('config')
    awful.util.spawn(string.format('ln -sfn %s/themes/%s %s/current_theme', config, theme, config))
    awesome.restart()
end

function tj_theme_file()
    local check_theme_files = {
        string.format('%s/current_theme/theme.lua', awful.util.getdir('config')),
        '/usr/share/awesome/themes/default/theme.lua'
    }
    for _, theme_file in pairs(check_theme_files) do
        if awful.util.file_readable(theme_file) then
            return theme_file
        end
    end
    return nil
end

function tj_tags(layout)
    local tagtable = {}
    for i = 1, tagnum do
        table.insert(tagtable, i)
    end
    return awful.tag(tagtable, s, layout)
end

function tj_wibox(s)
    return awful.wibox({ position = wibox_position, screen = s })
end

function build_theme_menu()
    local menu = {}
    local themes_dir = string.format('%s/themes', awful.util.getdir('config'))
    local themes_stat = posix.stat(themes_dir)
    if themes_stat and themes_stat.type == 'directory' then
        local theme_dirs = posix.dir(themes_dir)
        for _, theme_name in pairs(theme_dirs) do
            local theme_dir = string.format('%s/%s', themes_dir, theme_name)
            local theme_stat = posix.stat(theme_dir)
            if theme_stat and (theme_stat.type == 'directory' or theme_stat.type == 'link') and not theme_name:find('^\.\.?$') then
                local item = { theme_name, function() choose_theme(theme_name) end }
                table.insert(menu, item)
            end
        end
    end
    return menu
end

function tj_menu_and_launcher()
    local system_menu_items = {
        { 'Lock Screen',     'xscreensaver-command -lock', freedesktop.utils.lookup_icon({ icon = 'system-lock-screen'        }) },
        { 'Logout',           awesome.quit,                freedesktop.utils.lookup_icon({ icon = 'system-log-out'            }) },
        { 'Reboot System',   'gksudo "shutdown -r now"',   freedesktop.utils.lookup_icon({ icon = 'reboot-notifier'           }) },
        { 'Shutdown System', 'gksudo "shutdown -h now"',   freedesktop.utils.lookup_icon({ icon = 'system-shutdown'           }) }
    }
    local awesome_menu_items = {
        { 'Themes',          build_theme_menu(),           freedesktop.utils.lookup_icon({ icon = 'preferences-desktop-theme' }) },
        { 'Restart Awesome', awesome.restart,              freedesktop.utils.lookup_icon({ icon = 'gtk-refresh'               }) },
    }
    local top_menu_items = {
        { 'Applications', freedesktop.menu.new(),          freedesktop.utils.lookup_icon({ icon = 'start-here'                }) },
        { 'Debian',       debian.menu.Debian_menu.Debian,  freedesktop.utils.lookup_icon({ icon = 'debian-logo'               }) },
        { 'Awesome',      awesome_menu_items,              beautiful.awesome_icon                                                },
        { 'System',       system_menu_items,               freedesktop.utils.lookup_icon({ icon = 'system'                    }) },
        { 'Terminal',     freedesktop.utils.terminal,      freedesktop.utils.lookup_icon({ icon = 'terminal'                  }) }
    }
    local main_menu = awful.menu({ items = top_menu_items })
    local launcher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = main_menu })
    return main_menu, launcher
end

function tj_delightful()
    require('delightful.widgets.battery')
    require('delightful.widgets.cpu')
    require('delightful.widgets.datetime')
    require('delightful.widgets.imap')
    require('delightful.widgets.memory')
    require('delightful.widgets.network')
    require('delightful.widgets.pulseaudio')
    require('delightful.widgets.weather')

    if not delightful_widgets then
            delightful_widgets = {
            delightful.widgets.network,
            delightful.widgets.cpu,
            delightful.widgets.memory,
            delightful.widgets.weather,
            delightful.widgets.imap,
            delightful.widgets.battery,
            delightful.widgets.pulseaudio,
            delightful.widgets.datetime,
        }
    end
    if not delightful_config then
        delightful_config = {
            [delightful.widgets.cpu] = {
                command = 'gnome-system-monitor',
            },
            [delightful.widgets.imap] = {
                {
                    user      = 'myuser',
                    password  = 'mypassword',
                    host      = 'mail.example.com',
                    ssl       = true,
                    mailboxes = { 'INBOX', 'awesome' },
                    command   = 'evolution -c mail',
                },
            },
            [delightful.widgets.memory] = {
                command = 'gnome-system-monitor',
            },
            [delightful.widgets.weather] = {
                {
                    city = 'Helsinki',
                    command = 'gnome-www-browser http://ilmatieteenlaitos.fi/saa/Helsinki',
                },
            },
            [delightful.widgets.pulseaudio] = {
                mixer_command = 'pavucontrol',
            },
        }
    end
    return delightful_widgets, delightful_config
end

function tj_globalkeys(modkey)
    local globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, 'q',      function() awful.menu.clients({theme = {width=245}})   end)
    )
    if local_globalkeys then
        globalkeys = awful.util.table.join(globalkeys, local_globalkeys)
    end
    return globalkeys
end

function tj_clientkeys(modkey)
    local clientkeys = awful.util.table.join(
            awful.key({ modkey            }, 'Next',   function() awful.client.moveresize( 20,  20, -40, -40) end),
            awful.key({ modkey            }, 'Prior',  function() awful.client.moveresize(-20, -20,  40,  40) end),
            awful.key({ modkey            }, 'Home',   function() awful.client.moveresize(  0,  20,   0,   0) end),
            awful.key({ modkey            }, 'Insert', function() awful.client.moveresize(  0, -20,   0,   0) end),
            awful.key({ modkey            }, 'Delete', function() awful.client.moveresize(-20,   0,   0,   0) end),
            awful.key({ modkey            }, 'End',    function() awful.client.moveresize( 20,   0,   0,   0) end),
            awful.key({ modkey, 'Shift'   }, 't',
                function(c)
                    awful.client.property.set(c, 'titlebar', not awful.client.property.get(c, 'titlebar'))
                    awful.titlebar.toggle(c)
                end)
    )
    if local_clientkeys then
        clientkeys = awful.util.table.join(clientkeys, local_clientkeys)
    end
    return clientkeys
end

function tj_rules()
    local rules = {
        {
            rule       = { class        = 'mplayer2'  },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'mpv'  },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Vlc'       },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'xbmc.bin'  },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Kodi'      },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'jive'      },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Rhythmbox' },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Nautilus'  },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Firefox'   },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Vmware'    },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Vncviewer' },
            properties = { floating     = true        }
        },
        {
            rule       = { class        = 'Steam'     },
            properties = { floating     = true        }
        },
        {
            rule       = { name         = 'gst-launch-1.0' },
            properties = { floating     = true        }
        },
    }
    if local_rules then
        rules = awful.util.table.join(rules, local_rules)
    end
    return rules
end
