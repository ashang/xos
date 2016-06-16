FN=$SETUPDIR/vtn-external.yaml

rm -f $FN

cat >> $FN <<EOF
tosca_definitions_version: tosca_simple_yaml_1_0

imports:
   - custom_types/xos.yaml

description: autogenerated node tags file for VTN configuration

topology_template:
  node_templates:

    service#ONOS_CORD:
      type: tosca.nodes.ONOSService
      requirements:
      properties:
          kind: onos
          view_url: /admin/onos/onosservice/\$id$/
          no_container: true
          rest_hostname: onos-cord
          replaces: service_ONOS_CORD

    service#vtn:
      type: tosca.nodes.VTNService
      properties:
          view_url: /admin/vtn/vtnservice/\$id$/
          privateGatewayMac: 00:00:00:00:00:01
          localManagementIp: 172.27.0.1/24
          ovsdbPort: 6641
          sshUser: root
          sshKeyFile: /root/node_key
          sshPort: 22
          xosEndpoint: http://xos/
          xosUser: padmin@vicci.org
          xosPassword: letmein
          replaces: service_vtn

EOF

NODES=$( bash -c "source $SETUPDIR/admin-openrc.sh ; nova host-list" |grep compute|awk '{print $2}' )
I=0
for NODE in $NODES; do
    echo $NODE
    cat >> $FN <<EOF
    $NODE:
      type: tosca.nodes.Node

    # VTN bridgeId field for node $NODE
    ${NODE}_bridgeId_tag:
      type: tosca.nodes.Tag
      properties:
          name: bridgeId
          value: of:0000000000000001
      requirements:
          - target:
              node: $NODE
              relationship: tosca.relationships.TagsObject
          - service:
              node: service#ONOS_CORD
              relationship: tosca.relationships.MemberOfService

    # VTN dataPlaneIntf field for node $NODE
    ${NODE}_dataPlaneIntf_tag:
      type: tosca.nodes.Tag
      properties:
          name: dataPlaneIntf
          value: fabric
      requirements:
          - target:
              node: $NODE
              relationship: tosca.relationships.TagsObject
          - service:
              node: service#ONOS_CORD
              relationship: tosca.relationships.MemberOfService

    # VTN dataPlaneIp field for node $NODE
    ${NODE}_dataPlaneIp_tag:
      type: tosca.nodes.Tag
      properties:
          name: dataPlaneIp
          value: 10.168.0.253/24
      requirements:
          - target:
              node: $NODE
              relationship: tosca.relationships.TagsObject
          - service:
              node: service#ONOS_CORD
              relationship: tosca.relationships.MemberOfService

EOF
done

cat >> $FN <<EOF
    VTN_ONOS_app:
      type: tosca.nodes.ONOSVTNApp
      requirements:
          - onos_tenant:
              node: service#ONOS_CORD
              relationship: tosca.relationships.TenantOfService
          - vtn_service:
              node: service#vtn
              relationship: tosca.relationships.UsedByService
      properties:
          install_dependencies: http://new-host:8080/repository/org/opencord/cord-config/1.0-SNAPSHOT/cord-config-1.0-SNAPSHOT.oar,http://new-host:8080/repository/org/opencord/vtn/1.0-SNAPSHOT/vtn-1.0-SNAPSHOT.oar
          dependencies: org.onosproject.drivers, org.onosproject.drivers.ovsdb, org.onosproject.openflow-base, org.onosproject.ovsdb-base, org.onosproject.dhcp, org.opencord.vtn, 
          autogenerate: vtn-network-cfg
EOF
