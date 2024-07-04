FROM debian:latest

ENV DISPLAY=:1
ENV RESOLUTION=1024x768
ENV VNC_PASSWORD="superSecurePass131"

# Tools
ENV IDEA_VERSION="2024.1.4"

# Core Dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  xorg tigervnc-standalone-server fluxbox supervisor xterm bash fonts-wqy-zenhei novnc websockify tint2 x11-xserver-utils feh compton geany nano vim zsh \
  firefox-esr thunar sudo curl wget openjdk-17-jre sakura \
  fonts-terminus fonts-inconsolata fonts-dejavu fonts-noto fonts-noto-cjk fonts-font-awesome fonts-noto-extra git

# Dev Tools
# Download and install IntelliJ IDEA
RUN mkdir -p /opt/intellij && \
    curl -L "https://download.jetbrains.com/idea/ideaIC-${IDEA_VERSION}.tar.gz" -o /tmp/idea.tar.gz && \
    tar -xzf /tmp/idea.tar.gz --strip-components=1 -C /opt/intellij && \
    rm /tmp/idea.tar.gz && \
    chown -R $USER_NAME:$USER_NAME /opt/intellij
RUN rm -rf /opt/intellij/jbr

RUN mkdir -p /opt/intelliju && \
    curl -L "https://download.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz" -o /tmp/idea.tar.gz && \
    tar -xzf /tmp/idea.tar.gz --strip-components=1 -C /opt/intelliju && \
    rm /tmp/idea.tar.gz && \
    chown -R $USER_NAME:$USER_NAME /opt/intelliju
RUN rm -rf /opt/intelliju/jbr

# create symlink for noVNC config
RUN ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# move new supervisord config
ADD configs/supervisord.conf /etc/supervisord.conf
RUN echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Default Configs
COPY configs/skel/ /root/
RUN chmod +x /root/.fluxbox/startup
RUN echo "$full $full|/root/.fluxbox/backgrounds/lunawolf.png||:1.0" > /root/.fluxbox/lastwallpaper
RUN sed -i "s|command=/usr/bin/Xvnc :1 -geometry %(ENV_RESOLUTION) -depth 24 -rfbauth /root/.vnc/passwd|command=/usr/bin/Xvnc :1 -geometry $RESOLUTION -depth 24 -rfbauth /root/.vnc/passwd|g" /etc/supervisord.conf

WORKDIR /root

# Required Ports
EXPOSE 5901 6900

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
