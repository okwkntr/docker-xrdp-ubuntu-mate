FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

RUN echo 'apt-get update -qq && apt-get install -yq $@ && apt-get clean && rm -rf /var/lib/apt/lists/*' > /usr/local/bin/apt.sh \
    && chmod +x /usr/local/bin/apt.sh \
    && sed -i -e 's/archive/jp.archive/g' /etc/apt/sources.list

## add packages
RUN apt.sh \ 
	ubuntu-mate-desktop \
	mate-desktop-environment \
	mate-desktop-environment-extra

RUN apt-add-repository -y ppa:hermlnx/xrdp \
    && apt.sh xrdp \
    && apt-add-repository --remove -y ppa:hermlnx/xrdp
RUN sed -i -e "s|\(.*exec.*/etc/X11/Xsession.*\)|#\1|g" \
	    /etc/xrdp/startwm.sh \
	    && echo export GTP_IM_MODULE=ibus >>/etc/xrdp/startwm.sh \
	    && echo export QT_IM_MODULE=ibus >>/etc/xrdp/startwm.sh \
	    && echo export XMODIFIERS=\"@im=ibus\" >>/etc/xrdp/startwm.sh \
	    && echo ibus-daemon -d >>/etc/xrdp/startwm.sh \
	    && echo mate-session >>/etc/xrdp/startwm.sh

## set timezone
RUN ln -s -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && dpkg-reconfigure tzdata

RUN apt.sh ibus-mozc locales fonts-takao
RUN sed -i -e "s/^enabled=True/enabled=False/" /etc/xdg/user-dirs.conf \
    && sed -i -e "s/^# ja_JP.UTF-8/ja_JP.UTF-8/" /etc/locale.gen \
    && locale-gen \
    && update-locale LANG="ja_JP.UTF-8"
## ibus
ENV LANG "ja_JP.UTF-8"

RUN apt.sh vim less git

RUN apt-add-repository ppa:webupd8team/atom
RUN apt.sh atom 
RUN apt-add-repository --remove ppa:webupd8team/atom

WORKDIR /etc/xrdp
#COPY files/xrdp/km-e0010411.ini km-0411.ini
#RUN chmod 644 km-0411.ini \
#    && ln -s km-0411.ini km-e0010411.ini \
#    && ln -s km-0411.ini km-e0200411.ini \
#    && ln -s km-0411.ini km-e0210411.ini

## create vagrant account.uid:gid=1000:1000
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

RUN mkdir -p ${HOME}/.atom/packages
WORKDIR ${HOME}/.atom/packages
#RUN cp ${HOME}/.atom/config.cson ${HOME}/.atom/config.cson.back
#RUN awk '{print} /disabledPackages:/{flag=1;} \
#	 {if (flag==1) {print "    \"markdown-preview\""}; flag=0}'\
#	 ${HOME}/.atom/config.cson.back >${HOME}/.atom/config.cson
#RUN sudo -u ${USER} apm disable markdown-preview
RUN printf '"*":\n' > ${HOME}/.atom/config.cson; \
    printf '  core:\n' >> ${HOME}/.atom/config.cson; \
    printf '    disabledPackages: [\n' >> ${HOME}/.atom/config.cson; \
    printf '      "markdown-preview"\n' >> ${HOME}/.atom/config.cson; \
    printf '    ]\n' >> ${HOME}/.atom/config.cson \
    printf '  "markdown-preview-enhanced": {}\n' >> ${HOME}/.atom/config.cson \

RUN git clone https://github.com/shd101wyy/markdown-preview-enhanced.git

RUN chown -R "${USER}:${USER}" ${HOME}

#VOLUME ${HOME}
EXPOSE 3389
CMD (rm -f /var/run/xrdp/*; /etc/init.d/xrdp start; tail -f /dev/null)
