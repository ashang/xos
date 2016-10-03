import os
import pdb
import sys
import tempfile
sys.path.append("/opt/tosca")
from translator.toscalib.tosca_template import ToscaTemplate

from core.models import ServiceController, ServiceControllerResource, LoadableModule, LoadableModuleResource

from xosresource import XOSResource

class XOSServiceController(XOSResource):
    provides = "tosca.nodes.ServiceController"
    xos_model = ServiceController
    copyin_props = ["version", "provides", "requires", "base_url", "synchronizer_run", "synchronizer_config"]

    def postprocess_resource_prop(self, obj, kind, format):
        values = self.get_property(kind)
        if values:
            for i,value in enumerate(values.split(",")):
                value = value.strip()
                subdirectory = None

                name=kind
                if i>0:
                    name = "%s_%d" %( name, i)

                if (" " in value):
                    parts=value.split()
                    for part in parts[:-1]:
                       if ":" in part:
                           (lhs, rhs) = part.split(":", 1)
                           if lhs=="subdirectory":
                               subdirectory=rhs
                           else:
                               raise Exception("Malformed value %s" % value)
                       else:
                           raise Exception("Malformed value %s" % value)
                    value = parts[-1]


                scr = LoadableModuleResource.objects.filter(loadable_module=obj, name=name, kind=kind, format=format)
                if scr:
                    scr=scr[0]
                    if (scr.url != value) or (scr.subdirectory!=subdirectory):
                        self.info("updating resource %s" % kind)
                        scr.url = value
                        scr.subdirectory = subdirectory
                        scr.save()
                else:
                    self.info("adding resource %s" % kind)
                    scr = LoadableModuleResource(loadable_module=obj, name=name, kind=kind, format=format, url=value, subdirectory=subdirectory)
                    scr.save()

    def postprocess(self, obj):
        # allow these common resource to be specified directly by the ServiceController tosca object
        self.postprocess_resource_prop(obj, "models", "python")
        self.postprocess_resource_prop(obj, "admin", "python")
        self.postprocess_resource_prop(obj, "django_library", "python")
        self.postprocess_resource_prop(obj, "admin_template", "raw")
        self.postprocess_resource_prop(obj, "tosca_custom_types", "yaml")
        self.postprocess_resource_prop(obj, "tosca_resource", "python")
        self.postprocess_resource_prop(obj, "synchronizer", "manifest")
        self.postprocess_resource_prop(obj, "private_key", "raw")
        self.postprocess_resource_prop(obj, "public_key", "raw")
        self.postprocess_resource_prop(obj, "rest_service", "python")
        self.postprocess_resource_prop(obj, "rest_tenant", "python")

    def save_created_obj(self, xos_obj):
        if xos_obj.requires and xos_obj.requires.strip():
            (satisfied, missing) = ServiceController.dependency_check([x.strip() for x in xos_obj.requires.split(",")])
            if missing:
                raise Exception("missing dependencies for ServiceController %s: %s" % (xos_obj.name, ", ".join(missing)))

        super(XOSServiceController, self).save_created_obj(xos_obj)


