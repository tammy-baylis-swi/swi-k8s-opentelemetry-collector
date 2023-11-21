{{- define "common-config.filter-reciever" -}}
# Those metrics are generated by Prometheus reciever (https://prometheus.io/docs/concepts/jobs_instances/#automatically-generated-labels-and-time-series)
filter/receiver:
  metrics:
    exclude:
      match_type: strict
      metric_names:
        - scrape_duration_seconds
        - scrape_samples_post_metric_relabeling
        - scrape_samples_scraped
        - scrape_series_added
        - up
{{- end }}

{{- define "common-config.filter-remove-internal" -}}
# Remove datapoints of internal k8s containers from metrics, excluding the "container_network_.+_total" metric where other datapoints don't exist
# This is a workaround to not create container entities for POD containers
filter/remove_internal:
  metrics:
    datapoint:
      - 'attributes["container"] == "POD" and IsMatch(metric.name, "container_network_.*") == false'
{{- end }}

{{- define "common-config.attributes-remove-prometheus-attributes" -}}
attributes/remove_prometheus_attributes:    
  actions:
    - key: prometheus
      action: delete
    - key: prometheus_replica
      action: delete
{{- end }}

{{- define "common-config.transform-node-attributes" -}}
transform/unify_node_attribute:
  metric_statements:
    - context: datapoint
      statements:
        # use "service.instance.id" for Node name when the attributes/unify_node_attribute processor failed to provide it
        - set(attributes["k8s.node.name"], resource.attributes["service.instance.id"]) where IsMatch(metric.name, "^(container_.*)$") == true and attributes["k8s.node.name"] == nil
{{- end }}

{{- define "common-config.metricstransform-preprocessing-cadvisor" -}}
- include: k8s.container_fs_reads_total
  action: insert
  new_name: k8s.container_fs_reads_total_temp
- include: k8s.container_fs_writes_total
  action: insert
  new_name: k8s.container_fs_writes_total_temp
- include: (k8s.container_fs_reads_total_temp|k8s.container_fs_writes_total_temp)
  match_type: regexp
  action: combine
  submatch_case: lower
  experimental_match_labels: { "container": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  new_name: k8s.container.fs.iops
  operations:
    - action: aggregate_labels
      label_set:  [container, pod, namespace]
      aggregation_type: sum

- include: k8s.container_fs_reads_bytes_total
  action: insert
  new_name: k8s.container_fs_reads_bytes_total_temp
- include: k8s.container_fs_writes_bytes_total
  action: insert
  new_name: k8s.container_fs_writes_bytes_total_temp
- include: (k8s.container_fs_reads_bytes_total_temp|k8s.container_fs_writes_bytes_total_temp)
  match_type: regexp
  action: combine
  submatch_case: lower
  experimental_match_labels: { "container": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  new_name: k8s.container.fs.throughput
  operations:
    - action: aggregate_labels
      label_set:  [container, pod, namespace]
      aggregation_type: sum

- include: k8s.container_network_receive_bytes_total
  action: insert        
  new_name: k8s.container.network.bytes_received
- include: k8s.container_network_transmit_bytes_total
  action: insert        
  new_name: k8s.container.network.bytes_transmitted
- include: k8s.container_cpu_usage_seconds_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "container": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  new_name: k8s.pod.cpu.usage.seconds.rate
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
- include: k8s.container_cpu_usage_seconds_total
  action: insert
  new_name: k8s.container.cpu.usage.seconds.rate
- include: k8s.container_memory_working_set_bytes
  action: insert
  match_type: regexp
  experimental_match_labels: { "container": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  new_name: k8s.pod.memory.working_set
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
- include: k8s.container_network_receive_bytes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.network.bytes_received
- include: k8s.container_network_transmit_bytes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.network.bytes_transmitted
- include: k8s.container_network_receive_packets_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.network.packets_received
- include: k8s.container_network_transmit_packets_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.network.packets_transmitted
- include: k8s.container_network_receive_packets_dropped_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.network.receive_packets_dropped
- include: k8s.container_network_transmit_packets_dropped_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.network.transmit_packets_dropped
- include: k8s.container_fs_reads_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.reads.rate
- include: k8s.container_fs_writes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.writes.rate
- include: k8s.container_fs_reads_bytes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.reads.bytes.rate
- include: k8s.container_fs_writes_bytes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.writes.bytes.rate
- include: k8s.pod.fs.reads.rate
  action: insert
  new_name: k8s.pod.fs.reads.rate_temp
- include: k8s.pod.fs.writes.rate
  action: insert
  new_name: k8s.pod.fs.writes.rate_temp
- include: (k8s.pod.fs.reads.rate_temp|k8s.pod.fs.writes.rate_temp)
  match_type: regexp
  action: combine
  submatch_case: lower
  operations:
    - action: aggregate_labels
      label_set:  [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.iops
- include: k8s.pod.fs.reads.bytes.rate
  action: insert
  new_name: k8s.pod.fs.reads.bytes.rate_temp
- include: k8s.pod.fs.writes.bytes.rate
  action: insert
  new_name: k8s.pod.fs.writes.bytes.rate_temp
- include: (k8s.pod.fs.reads.bytes.rate_temp|k8s.pod.fs.writes.bytes.rate_temp)
  match_type: regexp
  action: combine
  submatch_case: lower
  operations:
    - action: aggregate_labels
      label_set:  [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.throughput
- include: k8s.container_fs_usage_bytes
  action: insert
  match_type: regexp
  experimental_match_labels: { "k8s.node.name": "\\S+", "pod": "\\S+", "namespace": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [pod, namespace, k8s.node.name]
      aggregation_type: sum
  new_name: k8s.pod.fs.usage.bytes
# k8s.node.name metrics
- include: k8s.container_cpu_usage_seconds_total
  action: insert
  experimental_match_labels: { "id": "/" }
  new_name: k8s.node.cpu.usage.seconds.rate
- include: k8s.container_memory_working_set_bytes
  action: insert
  experimental_match_labels: { "id": "/" }
  new_name: k8s.node.memory.working_set
- include: k8s.container_network_receive_bytes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "id":"/", "k8s.node.name": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.network.bytes_received
- include: k8s.container_network_transmit_bytes_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "id":"/", "k8s.node.name": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.network.bytes_transmitted
- include: k8s.container_network_receive_packets_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "id":"/", "k8s.node.name": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.network.packets_received
- include: k8s.container_network_transmit_packets_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "id":"/", "k8s.node.name": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.network.packets_transmitted
- include: k8s.container_network_receive_packets_dropped_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "id":"/", "k8s.node.name": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.network.receive_packets_dropped
- include: k8s.container_network_transmit_packets_dropped_total
  action: insert
  match_type: regexp
  experimental_match_labels: { "id":"/", "k8s.node.name": "\\S+" }
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.network.transmit_packets_dropped
- include: k8s.pod.fs.reads.rate
  action: insert
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.reads.rate_temp
- include: k8s.pod.fs.writes.rate
  action: insert
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.writes.rate_temp
- include: k8s.pod.fs.reads.bytes.rate
  action: insert
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.reads.bytes.rate_temp
- include: k8s.pod.fs.writes.bytes.rate
  action: insert
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.writes.bytes.rate_temp
- include: (k8s.node.fs.reads.rate_temp|k8s.node.fs.writes.rate_temp)
  match_type: regexp
  action: combine
  submatch_case: lower
  operations:
    - action: aggregate_labels
      label_set:  [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.iops
- include: (k8s.node.fs.reads.bytes.rate_temp|k8s.node.fs.writes.bytes.rate_temp)
  match_type: regexp
  action: combine
  submatch_case: lower
  operations:
    - action: aggregate_labels
      label_set:  [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.throughput
- include: k8s.pod.fs.usage.bytes
  action: insert
  operations:
    - action: aggregate_labels
      label_set: [k8s.node.name]
      aggregation_type: sum
  new_name: k8s.node.fs.usage
{{- end }}

{{- define "common-config.filter-remove-internal-post-processing" -}}
# Remove datapoints of internal k8s containers from "container_network_.+_total" metrics after they were already processed
# This is a workaround to not create container entities for POD containers
filter/remove_internal_postprocessing:
  metrics:
    datapoint:
    - 'attributes["container"] == "POD" and IsMatch(metric.name, "container_network_.*|k8s.container.*") == true'
{{- end }}

{{- define "common-config.attributes-remove-temp" -}}
attributes/remove_temp:
  include:
    match_type: regexp
    metric_names:
      - .*
  actions:
    - key: temp
      pattern: (.*_temp$)|(^\$.*) # attributes starting with $ are result of `combine` operations
      action: delete
{{- end }}

{{- define "common-config.cumulativetorate-cadvisor" -}}
- k8s.node.cpu.usage.seconds.rate
- k8s.pod.cpu.usage.seconds.rate
- k8s.container.fs.iops
- k8s.container.fs.throughput
- k8s.container.cpu.usage.seconds.rate
- k8s.container.network.bytes_received
- k8s.container.network.bytes_transmitted
- k8s.pod.fs.iops
- k8s.pod.fs.throughput
- k8s.pod.fs.reads.rate
- k8s.pod.fs.writes.rate
- k8s.pod.fs.reads.bytes.rate
- k8s.pod.fs.writes.bytes.rate
- k8s.pod.network.bytes_received
- k8s.pod.network.bytes_transmitted
- k8s.pod.network.packets_received
- k8s.pod.network.packets_transmitted
- k8s.pod.network.receive_packets_dropped
- k8s.pod.network.transmit_packets_dropped
- k8s.node.fs.iops
- k8s.node.fs.throughput
- k8s.node.network.bytes_received
- k8s.node.network.bytes_transmitted
- k8s.node.network.packets_received
- k8s.node.network.packets_transmitted
- k8s.node.network.receive_packets_dropped
- k8s.node.network.transmit_packets_dropped
{{- end }}

{{- define "common-config.groupbyattrs-node" -}}
groupbyattrs/node:
  keys:
    - k8s.node.name
{{- end }}

{{- define "common-config.groupbyattrs-pod" -}}
groupbyattrs/pod:
  keys:
    - namespace
    - pod
{{- end }}

{{- define "common-config.groupbyattrs-all" -}}
groupbyattrs/all:
  keys:
    - kubelet_version
    - container_runtime_version
    - provider_id
    - os_image
    - namespace
    - uid
    - k8s.pod.uid
    - pod_ip
    - host_ip
    - created_by_kind
    - created_by_name
    - host_network
    - priority_class
    - container_id
    - container
    - image
    - image_id
    - k8s.node.name
    - sw.k8s.pod.status
    - sw.k8s.namespace.status
    - sw.k8s.node.status
    - sw.k8s.container.status
    - sw.k8s.container.init
    - daemonset
    - statefulset
    - deployment
    - replicaset
    - job_name
    - cronjob
    - git_version
    - internal_ip
    - job_condition
    - persistentvolumeclaim
    - persistentvolume
    - sw.k8s.persistentvolumeclaim.status
    - sw.k8s.persistentvolume.status
    - storageclass
    - access_mode
    - k8s.service.name
    - sw.k8s.service.external_name
    - sw.k8s.service.type
    - sw.k8s.cluster.ip
{{- end }}

{{- define "common-config.resource-metrics" -}}
resource/metrics:
  attributes:      
    # Remove useless attributes
    - key: service.name
      action: delete

    - key: service.instance.id
      action: delete

    - key: net.host.name
      action: delete

    - key: net.host.port
      action: delete

    - key: http.scheme
      action: delete

    # Collector and Manifest version
    - key: sw.k8s.agent.manifest.version
      value: ${MANIFEST_VERSION}
      action: insert

    - key: sw.k8s.agent.app.version
      value: ${APP_VERSION}
      action: insert

    # Cluster
    - key: sw.k8s.cluster.uid
      value: ${CLUSTER_UID}
      action: insert

    - key: k8s.cluster.name
      value: ${CLUSTER_NAME}
      action: insert

    - key: sw.k8s.cluster.version
      from_attribute: git_version
      action: insert

    # k8s.node.name
    - key: sw.k8s.node.version
      from_attribute: kubelet_version
      action: insert      

    - key: sw.k8s.node.container.runtime.version
      from_attribute: container_runtime_version
      action: insert      

    - key: sw.k8s.node.provider.id
      from_attribute: provider_id
      action: insert      

    - key: sw.k8s.node.os.image
      from_attribute: os_image
      action: insert
    
    - key: sw.k8s.node.ip.internal
      from_attribute: internal_ip
      action: insert      

    # Namespace
    - key: k8s.namespace.name
      from_attribute: namespace
      action: insert      
    # Pod
    - key: k8s.pod.name
      from_attribute: pod
      action: insert

    - key: sw.k8s.pod.ip
      from_attribute: pod_ip
      action: insert

    - key: sw.k8s.pod.host.ip
      from_attribute: host_ip
      action: insert      

    - key: sw.k8s.pod.createdby.kind
      from_attribute: created_by_kind
      action: insert      

    - key: sw.k8s.pod.createdby.name
      from_attribute: created_by_name
      action: insert      

    - key: sw.k8s.pod.host.network
      from_attribute: host_network
      action: insert      

    - key: sw.k8s.pod.priority_class
      from_attribute: priority_class
      action: insert      

    # Container
    - key: container_id
      action: extract
      pattern: ^(?P<extracted_container_runtime>[^:]+)://(?P<extracted_container_id>[^/]+)$
    - key: container.id
      from_attribute: extracted_container_id
      action: insert      
    - key: container.runtime
      from_attribute: extracted_container_runtime
      action: insert      

    - key: k8s.container.name
      from_attribute: container
      action: insert      

    - key: k8s.container.image.id
      from_attribute: image_id
      action: insert      

    - key: k8s.container.image.name
      from_attribute: image
      action: insert      

    # ReplicaSet
    - key: k8s.replicaset.name
      from_attribute: replicaset
      action: insert      

    # Deployment
    - key: k8s.deployment.name
      from_attribute: deployment
      action: insert      

    # StatefulSet
    - key: k8s.statefulset.name
      from_attribute: statefulset
      action: insert

    # DaemonSet
    - key: k8s.daemonset.name
      from_attribute: daemonset
      action: insert      

    # Job
    - key: k8s.job.name
      from_attribute: job_name
      action: insert      

    - key: k8s.job.condition
      from_attribute: job_condition
      action: insert      

    # CronJob
    - key: k8s.cronjob.name
      from_attribute: cronjob
      action: insert      

    # PersistentVolume
    - key: k8s.persistentvolume.name
      from_attribute: persistentvolume
      action: insert      

    # PersistentVolumeClaim
    - key: k8s.persistentvolumeclaim.name
      from_attribute: persistentvolumeclaim
      action: insert
{{- end }}