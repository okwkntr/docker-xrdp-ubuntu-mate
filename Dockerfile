FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive

RUN echo 'echo "resolvconf resolvconf/linkify-resolvconf boolean false" \
            | debconf-set-selections \
            && apt-get update -qq \
            && apt-get install -yq $@ \
            && apt-get clean \
            && rm -rf /var/lib/apt/lists/*' \
    > /usr/local/bin/apt.sh \
    && chmod +x /usr/local/bin/apt.sh \
    && sed -i -e 's/archive/jp.archive/g' /etc/apt/sources.list

## add packages
RUN apt.sh \ 
    fonts-takao \
    ibus-mozc \
    locales \
    mate-desktop-environment \
    mate-desktop-environment-extra \
    tzdata \
    ubuntu-mate-desktop \
 && apt-add-repository -y ppa:hermlnx/xrdp \
    && apt.sh xrdp \
    && apt-add-repository --remove -y ppa:hermlnx/xrdp 

## setup configuration of packages
RUN sed -i -e "s/^enabled=True/enabled=False/" /etc/xdg/user-dirs.conf \
    && sed -i -e "s/^# ja_JP.UTF-8/ja_JP.UTF-8/" /etc/locale.gen \
    && locale-gen \
    && update-locale LANG="ja_JP.UTF-8" \
 && ln -s -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && dpkg-reconfigure tzdata

## create user account.uid:gid=1000:1000
ARG USER=jack
ARG PASSWORD=jack
ARG UID=1000
ARG GID=1000
ENV HOME /home/${USER}
RUN echo "${USER}:x:${UID}:${GID}:,,,:${HOME}:/bin/bash" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "${USER}:${PASSWORD}" | chpasswd
RUN mkdir /data && ln -s /data /home/${USER}
WORKDIR ${HOME}

RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# install atom packages
RUN apt-add-repository ppa:webupd8team/atom \
    && apt.sh atom \
    && apt-add-repository --remove ppa:webupd8team/atom

#RUN mkdir -p ${HOME}/.atom/packages
#WORKDIR ${HOME}/.atom/packages
#RUN printf '"*":\n' > ${HOME}/.atom/config.cson; \
#    printf '  core:\n' >> ${HOME}/.atom/config.cson; \
#    printf '    disabledPackages: [\n' >> ${HOME}/.atom/config.cson; \
#    printf '      "markdown-preview"\n' >> ${HOME}/.atom/config.cson; \
#    printf '    ]\n' >> ${HOME}/.atom/config.cson \
#    printf '  "markdown-preview-enhanced": {}\n' >> ${HOME}/.atom/config.cson

#RUN git clone https://github.com/shd101wyy/markdown-preview-enhanced.git

# Optional packages
#RUN apt.sh \
#    less \
#    git \
#    vim

#RUN chown -R "${USER}:${USER}" ${HOME}

#VOLUME ${HOME}
EXPOSE 3389
CMD (rm -rf /var/run/xrdp/*; \
     /etc/init.d/xrdp start; \
     /etc/init.d/dbus restart; \
     tail -f /var/log/xrdp.log)
