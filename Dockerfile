FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Update and install dependencies
RUN apt update && apt install -y \
    wget curl sudo gnupg2 \
    xfce4 xfce4-goodies \
    xterm dbus-x11 \
    novnc websockify \
    x11vnc xvfb \
    net-tools git unzip \
    libnss3 libatk-bridge2.0-0 libxss1 libasound2 libxshmfence1 libgtk-3-0 \
    && apt clean

# Create user
RUN useradd -m -s /bin/bash cursoruser && \
    echo "cursoruser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER cursoruser
WORKDIR /home/cursoruser

# Download and extract Cursor AppImage
RUN wget https://downloads.cursor.com/production/54c27320fab08c9f5dd5873f07fca101f7a3e076/linux/x64/Cursor-1.3.9-x86_64.AppImage -O Cursor.AppImage && \
    chmod +x Cursor.AppImage && \
    ./Cursor.AppImage --appimage-extract && \
    mv squashfs-root Cursor

# Set up noVNC and websockify
RUN git clone https://github.com/novnc/noVNC.git && \
    git clone https://github.com/novnc/websockify noVNC/utils/websockify

# Create startup script
RUN echo '#!/bin/bash\n\
Xvfb :1 -screen 0 1024x768x16 &\n\
sleep 2\n\
xfce4-session &\n\
/home/cursoruser/Cursor/AppRun &\n\
sleep 5\n\
x11vnc -display :1 -nopw -forever -shared -bg\n\
/home/cursoruser/noVNC/utils/launch.sh --vnc localhost:5900 --listen 6080' \
> /home/cursoruser/start.sh && chmod +x /home/cursoruser/start.sh

EXPOSE 6080

CMD ["/home/cursoruser/start.sh"]