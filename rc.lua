-- Configuration for Awesome 3.4
-- Copyright (C) 2011 Tuomas Jormola <tj@solitudo.net>
--
-- Licensed under the terms of GNU General Public License Version 2.0.
--
-- Features (see README for more detailed descriptions):
--
--    - awesome-freedesktop based menus
--    - Symlink based autostarting of applications
--    - Additional host specific configuration
--    - Wibox with Delightful support
--    - Almost default key bindings
--    - Floating mode rules for many applications

require('posix')
require('awful')
require('awful.autofocus')
require('awful.rules')

require('freedesktop.utils')
require('freedesktop.menu')

require('debian.menu')

-- Variable definitions

-- This is used later as the default terminal and editor to run.
terminal                   = 'gnome-terminal'
freedesktop.utils.terminal = terminal
editor                     = os.getenv('EDITOR') or 'editor'
editor_cmd                 = string.format('%s -e %s', terminal, editor)
mailer                     = 'mutt'
mailer_cmd                 = string.format('%s -e %s', terminal, mailer)
mixer                      = 'gnome-volume-control'
mixer_cmd                  = mixer

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = 'Mod4'

wibox_position = 'top'
tagnum = 4

-- Autostart
local autostart_dir = string.format('%s/autostart', awful.util.getdir('config'))
local autostart_stat = posix.stat(autostart_dir)
if autostart_stat and autostart_stat.type == 'directory' then
	local files = posix.dir(autostart_dir)
	if files then
		for _, file in pairs(files) do
			local full_file = string.format('%s/%s', autostart_dir, file)
			local file_stat = posix.stat(full_file)
			if file_stat and (file_stat.type == 'regular' or file_stat.type == 'link') then
				local command = full_file
				if file_stat.type == 'link' then
					local readlink_output = awful.util.pread(string.format('readlink %s', full_file))
					command = readlink_output:gsub('%s*$', '')
				end
				local basename = command:gsub('^.*/', '')
				if command then
					awful.util.spawn_with_shell(string.format('pgrep -u $USER -f "%s$" >/dev/null || ("%s" &)', basename, command))
				end
			end
		end
	end
end

-- Themes
-- Create a symlink from the given theme to ~/.config/awesome/current_theme
function choose_theme(theme)
	local config = awful.util.getdir('config')
	awful.util.spawn(string.format('ln -sfn %s/themes/%s %s/current_theme', config, theme, config))
	awesome.restart()
end
-- Load current configured theme or default theme
local check_themes = {
	string.format('%s/current_theme/theme.lua', awful.util.getdir('config')),
	'/usr/share/awesome/themes/default/theme.lua'
}
for i, v in pairs(check_themes) do
	if awful.util.file_readable(v) then
		beautiful.init(v)
		break
	end
end

-- Menus
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
	
local theme_menu = build_theme_menu()

local system_menu = {
	{ 'Lock Screen',     'xscreensaver-command -lock', freedesktop.utils.lookup_icon({ icon = 'system-lock-screen'        }) },
	{ 'Logout',           awesome.quit,                freedesktop.utils.lookup_icon({ icon = 'system-log-out'            }) },
	{ 'Reboot System',   'gksudo "shutdown -r now"',   freedesktop.utils.lookup_icon({ icon = 'reboot-notifier'           }) },
	{ 'Shutdown System', 'gksudo "shutdown -h now"',   freedesktop.utils.lookup_icon({ icon = 'system-shutdown'           }) }
}

local awesome_menu = {
	{ 'Themes',          theme_menu,                   freedesktop.utils.lookup_icon({ icon = 'preferences-desktop-theme' }) },
	{ 'Restart Awesome', awesome.restart,              freedesktop.utils.lookup_icon({ icon = 'gtk-refresh'               }) },
}

top_menu = {
	{ 'Applications', freedesktop.menu.new(),          freedesktop.utils.lookup_icon({ icon = 'start-here'                }) },
	{ 'Debian',       debian.menu.Debian_menu.Debian,  freedesktop.utils.lookup_icon({ icon = 'debian-logo'               }) },
	{ 'Awesome',      awesome_menu,                    beautiful.awesome_icon },
	{ 'System',       system_menu,                     freedesktop.utils.lookup_icon({ icon = 'system'                    }) },
	{ 'Terminal',     freedesktop.utils.terminal,      freedesktop.utils.lookup_icon({ icon = 'terminal'                  }) }
}

-- Tags
-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
	awful.layout.suit.floating,
	awful.layout.suit.tile,
	awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom,
	awful.layout.suit.tile.top,
	awful.layout.suit.fair,
	awful.layout.suit.fair.horizontal,
	awful.layout.suit.spiral,
	awful.layout.suit.spiral.dwindle,
	awful.layout.suit.max,
	awful.layout.suit.max.fullscreen,
	awful.layout.suit.magnifier
}

tags = {}
local tagtable = {}
for i = 1, tagnum do
	table.insert(tagtable, i)
end
-- Define a tag table which hold all screen tags.
for s = 1, screen.count() do
	-- Each screen has its own tag table.
	tags[s] = awful.tag(tagtable, s, layouts[4])
end

-- Local local config file
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

-- Wibox
local delightful_container = { widgets = {}, icons = {} }
if install_delightful then
	for _, widget in pairs(awful.util.table.reverse(install_delightful)) do
		local config = delightful_config and delightful_config[widget]
		local widgets, icons = widget:load(config)
		if not icons then
			icons = {}
		end
		table.insert(delightful_container.widgets, awful.util.table.reverse(widgets))
		table.insert(delightful_container.icons,   awful.util.table.reverse(icons))
	end
end

local taglist = {}
taglist.buttons = awful.util.table.join(
		awful.button({        }, 1, awful.tag.viewonly    ),
		awful.button({ modkey }, 1, awful.client.movetotag),
		awful.button({        }, 3, awful.tag.viewtoggle  ),
		awful.button({ modkey }, 3, awful.client.toggletag),
		awful.button({        }, 4, awful.tag.viewnext    ),
		awful.button({        }, 5, awful.tag.viewprev    )
)

local tasklist = {}
tasklist.buttons = awful.util.table.join(
		awful.button({ }, 1,
			function(c)
				if not c:isvisible() then
					awful.tag.viewonly(c:tags()[1])
				end
				client.focus = c
				c:raise()
			end),
		 awful.button({ }, 3,
			function()
				if instance then
					instance:hide()
					instance = nil
				else
					instance = awful.menu.clients({ width = 250 })
				end
			end),
		 awful.button({ }, 4,
			function()
				awful.client.focus.byidx(1)
				if client.focus then
					client.focus:raise()
				end
			end),
		 awful.button({ }, 5,
			function()
				awful.client.focus.byidx(-1)
				if client.focus then
					client.focus:raise()
				end
		end)
)

local main_menu = awful.menu.new({ items = top_menu, width = 150 })
local wibox      = {}
local layoutbox  = {}
local promptbox = {}
local launcher   = awful.widget.launcher({ image = image(beautiful.awesome_icon), menu = main_menu })
local systray    = widget({ type = 'systray'                     })
local spacer     = widget({ type = 'textbox', name = 'spacer'    })
local separator  = widget({ type = 'textbox', name = 'separator' })
spacer.text      = ' '
separator.text   = '|'

for s = 1, screen.count() do
	promptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })

	layoutbox[s] = awful.widget.layoutbox(s)
	layoutbox[s]:buttons(awful.util.table.join(
			awful.button({ }, 1, function() awful.layout.inc(layouts,  1) end),
			awful.button({ }, 3, function() awful.layout.inc(layouts, -1) end),
			awful.button({ }, 4, function() awful.layout.inc(layouts,  1) end),
			awful.button({ }, 5, function() awful.layout.inc(layouts, -1) end)
	))

	taglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, taglist.buttons)

	tasklist[s] = awful.widget.tasklist(
			function(c)
				return awful.widget.tasklist.label.currenttags(c, s)
			end,
			tasklist.buttons
	)

	wibox[s] = awful.wibox({ position = wibox_position, screen = s })
	local widgets_front = {
		{
			launcher,
			taglist[s],
			promptbox[s],
			spacer,
			layout = awful.widget.layout.horizontal.leftright
		},
		layoutbox[s],
		spacer,
	}
	local widgets_middle = {}
	for delightful_container_index, delightful_container_data in pairs(delightful_container.widgets) do
		table.insert(widgets_middle, separator)
		for widget_index, widget_data in pairs(delightful_container_data) do
			if delightful_container_index > 1 then
				table.insert(widgets_middle, spacer)
			end
			table.insert(widgets_middle, widget_data)
			if delightful_container.icons[delightful_container_index] and delightful_container.icons[delightful_container_index][widget_index] then
				table.insert(widgets_middle, delightful_container.icons[delightful_container_index][widget_index])
			end
			if delightful_container_index > 1 and widget_index == #delightful_container_data then
				table.insert(widgets_middle, spacer)
			end
		end
	end
	local widgets_end = {
		(s == 1 and #delightful_container.widgets > 0) and separator or nil,
		s == 1 and systray or nil,
		tasklist[s],
		layout = awful.widget.layout.horizontal.rightleft,
	}
	wibox[s].widgets = awful.util.table.join(widgets_front, widgets_middle, widgets_end)
end

-- Mouse bindings
root.buttons(awful.util.table.join(
		awful.button({ }, 3, function() main_menu:toggle() end),
		awful.button({ }, 4, awful.tag.viewnext                ),
		awful.button({ }, 5, awful.tag.viewprev                )
))

-- Key bindings
local globalkeys = awful.util.table.join(
		awful.key({ modkey,           }, 'Left',   awful.tag.viewprev                                        ),
		awful.key({ modkey,           }, 'Right',  awful.tag.viewnext                                        ),
		awful.key({ modkey,           }, 'Escape', awful.tag.history.restore                                 ),

		awful.key({ modkey,           }, "j",
			function ()
				awful.client.focus.byidx( 1)
				if client.focus then client.focus:raise() end
			end),
		awful.key({ modkey,           }, "k",
			function ()
				awful.client.focus.byidx(-1)
				if client.focus then client.focus:raise() end
			end),
		awful.key({ modkey,           }, 'w',      function() main_menu:show(true)                        end),
		awful.key({ modkey,           }, 'q',      function() awful.menu.clients({width=245})             end),

		-- Layout manipulation
		awful.key({ modkey, 'Shift'   }, 'j',      function() awful.client.swap.byidx(  1)                end),
		awful.key({ modkey, 'Shift'   }, 'k',      function() awful.client.swap.byidx( -1)                end),
		awful.key({ modkey, 'Control' }, 'j',      function() awful.screen.focus_relative( 1)             end),
		awful.key({ modkey, 'Control' }, 'k',      function() awful.screen.focus_relative(-1)             end),
		awful.key({ modkey,           }, 'u',      awful.client.urgent.jumpto                                ),
		awful.key({ modkey,           }, 'Tab',
			function()
				awful.client.focus.byidx( 1)
				if client.focus then
					client.focus:raise()
				end
			end),
		awful.key({ modkey, 'Shift'   }, 'Tab',
			function()
				awful.client.focus.byidx(-1)
				if client.focus then
					client.focus:raise()
				end
			end),

		-- Standard program
		awful.key({ modkey,           }, 'Return', function() awful.util.spawn(terminal)                  end),
		awful.key({ modkey, 'Control' }, 'r',      awesome.restart                                           ),
		awful.key({ modkey, 'Shift'   }, 'q',      awesome.quit                                              ),

		awful.key({ modkey,           }, 'l',      function() awful.tag.incmwfact( 0.05)                  end),
		awful.key({ modkey,           }, 'h',      function() awful.tag.incmwfact(-0.05)                  end),
		awful.key({ modkey, 'Shift'   }, 'h',      function() awful.tag.incnmaster( 1)                    end),
		awful.key({ modkey, 'Shift'   }, 'l',      function() awful.tag.incnmaster(-1)                    end),
		awful.key({ modkey, 'Control' }, 'h',      function() awful.tag.incncol( 1)                       end),
		awful.key({ modkey, 'Control' }, 'l',      function() awful.tag.incncol(-1)                       end),
		awful.key({ modkey,           }, 'space',  function() awful.layout.inc(layouts,  1)               end),
		awful.key({ modkey, 'Shift'   }, 'space',  function() awful.layout.inc(layouts, -1)               end),

		-- Prompt
		awful.key({ modkey },            'r',      function() promptbox[mouse.screen]:run()              end)
)

local clientkeys = awful.util.table.join(
		awful.key({ modkey            }, 'Next',   function() awful.client.moveresize( 20,  20, -40, -40) end),
		awful.key({ modkey            }, 'Prior',  function() awful.client.moveresize(-20, -20,  40,  40) end),
		awful.key({ modkey            }, 'Home',   function() awful.client.moveresize(  0,  20,   0,   0) end),
		awful.key({ modkey            }, 'Insert', function() awful.client.moveresize(  0, -20,   0,   0) end),
		awful.key({ modkey            }, 'Delete', function() awful.client.moveresize(-20,   0,   0,   0) end),
		awful.key({ modkey            }, 'End',    function() awful.client.moveresize( 20,   0,   0,   0) end),
		awful.key({ modkey,           }, 'f',      function(c) c.fullscreen = not c.fullscreen            end),
		awful.key({ modkey, 'Shift'   }, 'c',      function(c) c:kill()                                   end),
		awful.key({ modkey, 'Control' }, 'space',  awful.client.floating.toggle                              ),
		awful.key({ modkey, 'Control' }, 'Return', function(c) c:swap(awful.client.getmaster())           end),
		awful.key({ modkey,           }, 'o',      awful.client.movetoscreen                                 ),
		awful.key({ modkey, 'Shift'   }, 'r',      function(c) c:redraw()                                 end),
		awful.key({ modkey,           }, 'n',      function(c) c.minimized = not c.minimized              end),
		awful.key({ modkey,           }, 'm',
			function(c)
				c.maximized_horizontal = not c.maximized_horizontal
				c.maximized_vertical   = not c.maximized_vertical
			end),
		awful.key({ modkey,           }, 't',
			function(c)
				local t = awful.client.property.get(c, 'titlebar') or false
				awful.client.property.set(c, 'titlebar', not t)
				if t then
					awful.titlebar.remove(c)
				else
					awful.titlebar.add(c, { modkey = modkey })
				end
			end)
)

-- Add host client key bindings
if host_clientkeys then
	clientkeys = awful.util.table.join(clientkeys, host_clientkeys)
end

-- Compute the maximum number of digit we need, limited to 9
local keynumber = 0
for s = 1, screen.count() do
	keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
	globalkeys = awful.util.table.join(globalkeys,
			awful.key({ modkey }, '#' .. i + 9,
				function()
					local screen = mouse.screen
					if tags[screen][i] then
						awful.tag.viewonly(tags[screen][i])
					end
				end),
			awful.key({ modkey, 'Control' }, '#' .. i + 9,
				function()
					local screen = mouse.screen
					if tags[screen][i] then
						awful.tag.viewtoggle(tags[screen][i])
					end
				end),
			awful.key({ modkey, 'Shift' }, '#' .. i + 9,
				function()
					if client.focus and tags[client.focus.screen][i] then
						awful.client.movetotag(tags[client.focus.screen][i])
					end
				end),
			awful.key({ modkey, 'Control', 'Shift' }, '#' .. i + 9,
				function()
					if client.focus and tags[client.focus.screen][i] then
						awful.client.toggletag(tags[client.focus.screen][i])
					end
				end)
	)
end

-- Add host global key bindings
if host_globalkeys then
	globalkeys = awful.util.table.join(globalkeys, host_globalkeys)
end

local clientbuttons = awful.util.table.join(
		awful.button({        }, 1, function(c) client.focus = c; c:raise() end),
		awful.button({ modkey }, 1, awful.mouse.client.move                     ),
		awful.button({ modkey }, 3, awful.mouse.client.resize                   )
)

root.keys(globalkeys)

-- Rules
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule       = { },
		properties = {
  				       border_width = beautiful.border_width,
				       border_color = beautiful.border_normal,
				       focus        = true,
				       keys         = clientkeys,
				       buttons      = clientbuttons
		}
	},
	{
		rule       = { class        = 'MPlayer'   },
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
		rule       = { class        = 'pinentry'  },
		properties = { floating     = true        }
	},
	{
		rule       = { class        = 'Gimp'      },
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
}
-- Add host rules
if host_rules then
	awful.rules.rules = awful.util.table.join(awful.rules.rules, host_rules)
end

-- Signals
-- Signal function to execute when a new client appears.
client.add_signal('manage',
		function(c, startup)
			-- Enable sloppy focus
			c:add_signal('mouse::enter',
					function(c)
						if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
								and awful.client.focus.filter(c) then
							client.focus = c
						end
					end
			)

			if not startup then
				-- Set the windows at the slave,
				-- i.e. put it at the end of others instead of setting it master.
				awful.client.setslave(c)

				-- Put windows in a smart way, only if they does not set an initial position.
				if not c.size_hints.user_position and not c.size_hints.program_position then
					awful.placement.no_overlap(c)
					awful.placement.no_offscreen(c)
				end
			end
		end
)

client.add_signal('focus',   function(c) c.border_color = beautiful.border_focus  end)
client.add_signal('unfocus', function(c) c.border_color = beautiful.border_normal end)
