FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
#ENV http_proxy ${HTTP_PROXY}
#ENV https_proxy ${HTTPS_PROXY}

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
    mate-desktop-environment \
    mate-desktop-environment-extra \
    ubuntu-mate-desktop

RUN apt-add-repository -y ppa:hermlnx/xrdp \
    && apt.sh xrdp \
    && apt-add-repository --remove -y ppa:hermlnx/xrdp

RUN sed -i -e "s|\(.*exec.*/etc/X11/Xsession.*\)|#\1|g" /etc/xrdp/startwm.sh \
    && echo export GTP_IM_MODULE=ibus >>/etc/xrdp/startwm.sh \
    && echo export QT_IM_MODULE=ibus >>/etc/xrdp/startwm.sh \
    && echo export XMODIFIERS=\"@im=ibus\" >>/etc/xrdp/startwm.sh \
    && echo ibus-daemon -dx >>/etc/xrdp/startwm.sh \
    && echo mate-session >>/etc/xrdp/startwm.sh

## set timezone
RUN ln -s -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && dpkg-reconfigure tzdata

RUN mkdir -p /usr/share/locale-langpack/ja
RUN apt.sh language-pack-gnome-ja \
	   language-pack-gnome-ja-base \
	   language-pack-ja language-pack-ja-base \
	   fonts-takao-gothic fonts-takao-mincho \
     	   $(check-language-support)
RUN apt.sh ibus-mozc locales
RUN sed -i -e "s/^enabled=True/enabled=False/" /etc/xdg/user-dirs.conf \
    && sed -i -e "s/^# ja_JP.UTF-8/ja_JP.UTF-8/" /etc/locale.gen \
    && locale-gen \
    && update-locale LANG="ja_JP.UTF-8"
## ibus
ENV LANG "ja_JP.UTF-8"

RUN apt.sh vim less git


## create user account.uid:gid=1000:1000
ARG USER=jack
ARG PASSWORD=jack
ARG UID=1000
ARG GID=1000
ENV HOME /home/${USER}
RUN export uid=${UID} gid=${GID} \
    && echo "${USER}:x:${uid}:${gid}:Developer,,,:${HOME}:/usr/bin/fizsh" >> /etc/passwd \
    && echo "${USER}:x:${uid}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "${USER}:${PASSWORD}" | chpasswd
WORKDIR ${HOME}

RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# install atom packages

#RUN apt-add-repository ppa:webupd8team/atom
#RUN apt.sh atom 
#RUN apt-add-repository --remove ppa:webupd8team/atom

#RUN mkdir -p ${HOME}/.atom/packages
#WORKDIR ${HOME}/.atom/packages
#RUN printf '"*":\n' > ${HOME}/.atom/config.cson; \
#    printf '  core:\n' >> ${HOME}/.atom/config.cson; \
#    printf '    disabledPackages: [\n' >> ${HOME}/.atom/config.cson; \
#    printf '      "markdown-preview"\n' >> ${HOME}/.atom/config.cson; \
#    printf '    ]\n' >> ${HOME}/.atom/config.cson \
#    printf '  "markdown-preview-enhanced": {}\n' >> ${HOME}/.atom/config.cson
#
#RUN git clone https://github.com/shd101wyy/markdown-preview-enhanced.git

RUN chown -R "${USER}:${USER}" ${HOME}

#VOLUME ${HOME}
EXPOSE 3389
CMD (rm -rf /var/run/xrdp/*; \
     /etc/init.d/xrdp start; \
     /etc/init.d/dbus restart; \
     tail -f /var/log/xrdp.log)
