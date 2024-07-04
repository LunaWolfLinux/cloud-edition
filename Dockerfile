FROM debian:latest

ENV DISPLAY=:1
ENV RESOLUTION=1024x768
ENV VNC_PASSWORD="superSecurePass131"
ENV USER_NAME="devbox"
ENV USER_PASSWORD="superSecurePass131"

# Tools
ENV IDEA_VERSION="2024.1.4"

# Core Dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  xorg tigervnc-standalone-server fluxbox supervisor xterm bash fonts-wqy-zenhei novnc websockify tint2 x11-xserver-utils feh compton geany nano vim zsh \
  firefox-esr thunar sudo curl wget openjdk-17-jre sakura \
  fonts-terminus fonts-inconsolata fonts-dejavu fonts-noto fonts-noto-cjk fonts-font-awesome fonts-noto-extra git

# add a new user and set the same password for the new user and root
RUN adduser --disabled-password --gecos "" $USER_NAME && \
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd && \
    echo "root:$USER_PASSWORD" | chpasswd

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

# Create new User
RUN mkdir -p /home/$USER_NAME/.vnc && \
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/$USER_NAME/.vnc/passwd && \
    chmod 600 /home/$USER_NAME/.vnc/passwd && \
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.vnc
RUN echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Default Configs
COPY configs/skel/ /home/$USER_NAME/
RUN chmod +x /home/$USER_NAME/.fluxbox/startup
RUN echo "$full $full|/home/$USER_NAME/.fluxbox/backgrounds/lunawolf.png||:1.0" > /home/$USER_NAME/.fluxbox/lastwallpaper

# Ensure user owns the home directory
RUN chown -R $USER_NAME:$USER_NAME /home/$USER_NAME
RUN sed -i "s|command=/usr/bin/Xvnc :1 -geometry %(ENV_RESOLUTION) -depth 24 -rfbauth /home/%(ENV_USER_NAME)/.vnc/passwd|command=/usr/bin/Xvnc :1 -geometry $RESOLUTION -depth 24 -rfbauth /home/$USER_NAME/.vnc/passwd|g" /etc/supervisord.conf

# Switch User
USER $USER_NAME
WORKDIR /home/$USER_NAME

COPY configs/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Required Ports
EXPOSE 5901 6900

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
