RUN mkdir -p /root/setup
ADD xos/configurations/common/admin-openrc.sh /root/setup/
ADD xos/configurations/common/flat_net_name /root/setup/
ADD xos/configurations/common/cloudlab-nodes.yaml /opt/xos/configurations/commmon/
ADD xos/configurations/common/id_rsa.pub /root/setup/padmin_public_key

CMD /usr/bin/make -C /opt/xos/configurations/bash -f Makefile.inside; /bin/bash

#CMD ["/bin/bash"]
