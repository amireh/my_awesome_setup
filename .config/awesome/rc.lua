package.path = "/home/kandie/Workspace/Projects/awesome_scripts/?.lua;" .. package.path

-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("lfs")
require("daily_prayer_times")
-- require("/home/kandie/Workspace/Projects/daily_prayer_times/daily_prayer_times.lua")
-- require("volume")

 -- launch the Cairo Composite Manager
 -- awful.util.spawn_with_shell("cairo-compmgr &")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- print("Converted time: " .. offset_h .. ":" .. offset_m)
-- print("Past prayer was: " .. prayer_names[past_prayer] .. ", upcoming prayer is: " .. prayer_names[next_prayer] .. " (in " .. offset .. " seconds)")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
-- beautiful.init("/usr/share/awesome/themes/default/theme.lua")
-- beautiful.init(awful.util.getdir("config") .. "/themes/kandie/theme.lua")
beautiful.init("/home/kandie/.config/awesome/themes/kandie/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "terminal"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
altkey = "Mod1"
modaltshiftkey = { modkey, altkey, "Shift" }

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating, -- 1
    awful.layout.suit.tile, -- 2
    awful.layout.suit.tile.left, -- 3
    awful.layout.suit.tile.bottom, -- 4
    awful.layout.suit.tile.top, -- 5
    awful.layout.suit.fair, -- 6
    awful.layout.suit.fair.horizontal, -- 7
    awful.layout.suit.spiral, -- 8
    awful.layout.suit.spiral.dwindle, -- 9
    awful.layout.suit.max, -- 10
    awful.layout.suit.max.fullscreen, -- 11
    awful.layout.suit.magnifier -- 12
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
-- tags = {}
 tags = {
  screens = {
    {
      names  = { "fnav", "fmgmt", "www", "code", "code", "code", "music", "vlc", "freebie" },
      layouts = { layouts[10], layouts[6],  layouts[10], 
                  layouts[10], layouts[10], layouts[10], 
                  layouts[10], layouts[1],  layouts[1]  }
    },
    {
      names  = { "im", "mail", "www", "term", "term", "term", "suterm", "suterm", "suterm" },
      layouts = { layouts[1],   layouts[10], layouts[10], 
                  layouts[3],   layouts[3], layouts[3],
                  layouts[6],   layouts[6], layouts[10] }
    }
  }
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    -- tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
    tags[s] = awful.tag(tags.screens[s].names, s, tags.screens[s].layouts)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = {}
for s = 1, screen.count() do
  mysystray[s] = widget({ type = "systray" })
end

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

myprayer_timer = require 'prayer_timer_widget'

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = "18" })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            -- volume_widget,
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        s == 1 and myprayer_timer or nil,
        -- s == 1 and mysystray or nil,
        mysystray[s],
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

function list_iter(t)
  local i = 0
  local n = table.getn(t)
  return function ()
    i = i + 1
    if i <= n then return t[i] else return nil end
  end
end

theme_directories = {}
themes_root = "/usr/share/awesome/themes"
for dir in lfs.dir(themes_root) do
  if lfs.attributes(themes_root .. "/" .. dir, "mode") == "directory" then
    if dir ~= "." and dir ~= ".." and dir ~= "0-screenshots" then
      table.insert(theme_directories, dir)
    end
  end
end

current_theme = nil
current_theme_idx = 0
function switch_theme(next_idx)
  new_theme = nil
  theme_located = false
  
  if not current_theme then
    current_theme_idx = 1
    new_theme = theme_directories[current_theme_idx]
  else
    current_theme_idx = current_theme_idx + next_idx
    if (current_theme_idx < 1) then
      current_theme_idx = table.getn(theme_directories) - 1
    elseif(current_theme_idx > table.getn(theme_directories)) then
      current_theme_idx = 1
    end

    new_theme = theme_directories[current_theme_idx]
  end

  current_theme = new_theme
  beautiful.init(themes_root .. "/" .. current_theme .. "/theme.lua")
  naughty.notify({ text = "Switching theme: " .. current_theme })  

  awful.tag.viewprev()
  awful.tag.viewnext()
end

function next_theme()
  switch_theme(1)
end

function prev_theme()
  switch_theme(-1)
end

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey, altkey    }, "]",      next_theme             ),
    awful.key({ modkey, altkey    }, "[",      prev_theme             ),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key( modaltshiftkey,       "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Shift" }, "Tab", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ altkey,           }, "`", function () awful.util.spawn(terminal) end),
    awful.key(  modaltshiftkey,      "r", awesome.restart),
    awful.key(  modaltshiftkey,      "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key( modaltshiftkey, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- Application Shortcuts
    awful.key({ "Shift", altkey }, "w", function() awful.util.spawn("thunar") end),
    awful.key({ "Shift", altkey }, "s", function() awful.util.spawn("skype") end),
    awful.key({ "Shift", altkey }, "p", function() awful.util.spawn("pidgin") end),
    awful.key({ "Shift", altkey }, "x", function() awful.util.spawn("xchat") end),
    awful.key({ "Shift", altkey }, "c", function() awful.util.spawn("chromium") end),
    awful.key({ "Shift", altkey }, "f", function() awful.util.spawn("firefox") end),
    awful.key({ "Shift", altkey }, "t", function() awful.util.spawn("thunderbird") end),
    awful.key({ "Shift", altkey }, "b", function() awful.util.spawn("banshee") end),
    awful.key({ "Shift", altkey }, "e", function() awful.util.spawn("subl -n -b /home/kandie/Workspace/Projects") end),
    awful.key({ "Shift", altkey }, "n", function() awful.util.spawn("leafpad") end),

    -- Volume Control
    awful.key({ "Shift", altkey }, "+", function () awful.util.spawn("amixer set Master 5%+") end),
    awful.key({ "Shift", altkey }, "-", function () awful.util.spawn("amixer set Master 5%-") end),
    awful.key({ "Shift", altkey, "Control"}, "-", function () awful.util.spawn("amixer sset Master toggle") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,  "Shift"  }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ "Control"   }, "q",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey, "Shift"  }, "x",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
local grid_keymap = { "q", "w", "e", "a", "s", "d", "z", "x", "c" }
for i = 1, keynumber do
  local __curr_key = grid_keymap[i]
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, __curr_key, -- "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        -- awful.key({ modkey, "Control" }, __curr_key, -- "#" .. i + 9,
        --           function ()
        --               local screen = mouse.screen
        --               if tags[screen][i] then
        --                   awful.tag.viewtoggle(tags[screen][i])
        --               end
        --           end)
        awful.key({ "Control", modkey }, __curr_key, -- "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end))
        -- awful.key({ modkey, "Control", "Shift" }, __curr_key, -- "#" .. i + 9,
        --           function ()
        --               if client.focus and tags[client.focus.screen][i] then
        --                   awful.client.toggletag(tags[client.focus.screen][i])
        --               end
        --           end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     maximized_vertical   = false,
                     maximized_horizontal = false,                     
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
-- client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
