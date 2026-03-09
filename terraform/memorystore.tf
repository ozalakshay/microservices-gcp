# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create the Memorystore (redis) instance
resource "google_redis_instance" "redis-cart" {
  name           = "redis-cart"
  memory_size_gb = 1
  region         = var.region

  # count specifies the number of instances to create;
  # if var.memorystore is true then the resource is enabled
  count = var.memorystore ? 1 : 0
  redis_version = "REDIS_7_0"
  project       = var.gcp_project_id


  depends_on = [
    module.enable_google_apis
  ]
}

# Configure Online Boutique to target the Memorystore instance at deploy time.
resource "null_resource" "configure_memorystore_workload" {
  count = var.memorystore ? 1 : 0

  triggers = {
    redis_host = google_redis_instance.redis-cart[0].host
    redis_port = tostring(google_redis_instance.redis-cart[0].port)
  }

  # count specifies the number of instances to create;
  # if var.memorystore is true then the resource is enabled
  count          = var.memorystore ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-ec"]
    command     = <<-EOT
    kubectl set env deployment/cartservice REDIS_ADDR=${self.triggers.redis_host}:${self.triggers.redis_port} -n ${var.namespace}
    kubectl rollout status deployment/cartservice -n ${var.namespace} --timeout=${var.cartservice_rollout_timeout}
    EOT
  }
  depends_on = [
    resource.null_resource.apply_deployment
  ]
}
