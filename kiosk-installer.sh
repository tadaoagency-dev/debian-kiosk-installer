#!/bin/bash

# be new
apt-get update

# get software
apt-get install unclutter xorg chromium openbox lightdm locales ssh isc-dhcp-server -y

# Enable ssh server
service ssh start

# dir
mkdir -p /home/kiosk/.config/openbox

# create group
groupadd kiosk

# create user if not exists
id -u kiosk &>/dev/null || useradd -m kiosk -g kiosk -s /bin/bash 

# rights
chown -R kiosk:kiosk /home/kiosk

# don't remove virtual consoles
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "false"
EndSection
EOF

# create config
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi
cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=kiosk
user-session=openbox
EOF


# create DHCP SERVER on eth0
if [ -e "/etc/network/interfaces" ]; then
  mv /etc/network/interfaces /etc/network/interfaces.backup
fi
cat > /etc/network/interfaces << EOF
auto eth0
iface eth0 inet static
address 10.0.83.2 # server's IP address
netmask 255.255.255.0
network 10.0.83.0
broadcast 10.0.83.255
gateway 10.0.83.1 #router's IP address
EOF
if [ -e "/etc/dhcp/dhcpd.conf" ]; then
  mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
fi
cat > /etc/dhcp/dhcpd.conf << EOF
auto eth0
iface eth0 inet static
address 10.0.83.2 # server's IP address
netmask 255.255.255.0
network 10.0.83.0
broadcast 10.0.83.255
gateway 10.0.83.1 #router's IP address
EOF
/etc/init.d/isc-dhcp-server restart
ifup eth0


# create autostart
# Replace xrandr --auto with xrandr -o left or right for vertical kiosk
if [ -e "/home/kiosk/.config/openbox/autostart" ]; then
  mv /home/kiosk/.config/openbox/autostart /home/kiosk/.config/openbox/autostart.backup
fi
cat > /home/kiosk/.config/openbox/autostart << EOF
#!/bin/bash

unclutter -idle 0.1 -grab -root &

while :
do
  xrandr --auto
  chromium \
    --no-first-run \
    --start-maximized \
    --disable \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
    --incognito \
    --kiosk "https://neave.tv/"
  sleep 5
done &
EOF

echo "Done!"
