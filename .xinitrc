#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

#if [ -d /etc/X11/xinit/xinitrc.d ]; then
#  for f in /etc/X11/xinit/xinitrc.d/*; do
#    [ -x "$f" ] && . "$f"
#  done
#  unset f
#fi

setxkbmap -option terminate:ctrl_alt_bksp

xset +fp /usr/share/fonts/local
xset fp rehash

export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

# GNOME 3
# exec ck-launch-session dbus-launch --exit-with-session gnome-session
# exec ck-launch-session gnome-session
# exec gnome-shell

# MATE
# exec ck-launch-session mate-session

# XFCE 4.8
# exec ck-launch-session dbus-launch --exit-with-session startxfce4
# exec ck-launch-session dbus-launch xfce4-session

# Fluxbox
# exec ck-launch-session dbus-launch startfluxbox
# exec startfluxbox 

# LXDE
# exec ck-launch-session startlxde

# KDE
# exec ck-launch-session startkde 

# E17
# exec enlightenment_start

# Awesome
# exec awesome

# Awesome with GNOME 3
gnome-settings-daemon &      # handles themes, starts gnome-screensaver. You may have to use gconf to disable it setting the background.
nm-applet &                  # assuming you're using Network Manager
gnome-power-manager &        # for laptops and stuff
gnome-volume-manager &       # for mounting CDs, USB sticks, and such
eval `gnome-keyring-daemon`  # SSH/GPG agent
exec awesome                 # awesome receives xinit's process id; when it terminates, X will be terminated

# Cinnamon
# exec ck-launch-session gnome-session-cinnamon
