---
<!-- marp: true -->
---

<!-- $theme: default -->
<style>
section {
  background: yellow;
}
header,
footer {
  position: absolute;
  left: 50px;
  right: 50px;
  height: 20px;
}

header {
  top: 30px;
}

footer {
  bottom: 30px;
}
</style>

# StackMon

Observation platform for OpenStack based clouds

> ## Artem Goncharov
> ## Nils Magnus

---
## Agenda

- Why not ...XYZ
- What
- How

---
## Why (and why not ...XYZ)

What we wanted is:

  - Monitoring cloud from end user perspective
  - different metric physics (latencies, rates, occurences)
  - Events vs metrics
  - easy extensibility and readability and clarity
  - status page with SLA calculation (convert raw metrics into service status)
<br/>
*StackMon is a combination of existing tools rather then another monitoring
system.*

---
## What (are we doing)

```mermaid
flowchart LR
  user[User]
  internet
  style internet stroke-dasharray: 5 5;

  subgraph cloud ["OpenStack"]
    direction LR
    api[OpenStack API]
    nova[Nova]
    neutron[Neutron]
    keystone[Keystone]
    api --> nova
    api --> neutron
    api --> keystone
  end

  subgraph stackmon ["StackMon"]
    runner["Test runner"]
    tsdb
    runner --> tsdb
    tsdb --> dashboard
  end

  user -->|uses| internet
  internet --> api
  runner --> internet 
```

---
## How (are we doing that)

Key Facts:

- Ansible playbook as a testing scenario
- Metrics emited by OpenStackSDK under the hood
- Additional metrics gathering plugins (i.e. static resources)
- Metrics processed through StatsD and stored in Graphite
- Metric Processor converts raw data into flags and semapthores with complex
  logic
- Status dashboard visualizes service semaphores

---
### Design

```mermaid
flowchart LR

  A[Alerta]
  StatsD[StatsD]
  Swift[(Logs)]
  Graphite[GraphiteDB]
  M[Metric Processor]
  Grafana[Grafana Dashboard]
  DB1[(SQL Database)]
  SD[Status Dashboard]
  
  subgraph tester ["Testing framework"]
    direction LR
    subgraph apimon ["StackMon plugin ApiMon"]
      SCH[Scheduler]
      EX[Executor\n X,Y,..]
      subgraph Ansible
          style Ansible stroke:#333,stroke-width:3px;
          P[Playbook]
          SDK[Openstack SDK]
      end
    end
  
    subgraph epmon ["StackMon plugin EpMon"]
      direction LR
      E[Endpoint Monitor]
    end
  
    C[StackMon\n plugin X,Y,..]
  end
  
  subgraph backend ["Backend"]
    direction LR
    A
    StatsD
    Graphite
    M
    DB1
    Swift
  end
  
  subgraph frontend ["Representation layer"]
    direction LR
    Grafana
    SD
  end
  
  tester --> backend
  backend --> frontend
```

---
## Testing options

- ApiMon - Ansible driven playbook scheduler/executor
- EpMon - Endpoint monitoring
- xxx - Arbitrary testing container doing something and producing metrics

---
## ApiMon

```yaml
- name: Test Image
  hosts: localhost
  tasks:
    - block:

        - name: List Images
          openstack.cloud.image_info:

        - name: Get single Image
          openstack.cloud.image_info:
            image: "Standard_Fedora_38_latest"

        - name: Create directory for images
          ansible.builtin.file:
            name: /tmp/ansible/images
            state: directory
            recurse: true

        - name: Download cirros image
          ansible.builtin.get_url:
            url: https://download.cirros-cloud.net/0.6.0/cirros-0.6.0-x86_64-disk.img
            dest: /tmp/ansible/images/cirros.img
            validate_certs: false

        - name: Upload cirros image
          openstack.cloud.image:
            name: "{{ image_name }}"
            container_format: bare
            disk_format: qcow2
            state: present
            min_disk: 1
            timeout: 1200
            is_protected: false
            filename: /tmp/ansible/images/cirros.img
          tags:
            - "metric=image_upload"

      always:
        - name: Delete cirros image
          openstack.cloud.image:
            name: "{{ image_name }}"
            state: absent
          tags:
            - "metric=image_delete"
```

---
## EpMon

Dummy GET requests to the URL of the endpoint
```yaml
  ...
  compute:
    service_type: compute
    urls:
    - /
    - /servers
    - /flavors
    - /limits
    - /os-keypairs
    - /os-server-groups
    - /os-availability-zone
  ...
```

---
## Under the hood (OpenStackSDK)

OpenStackSDK used by Ansible (ApiMon) and EpMon emits StatsD metrics.

For complex cases custom metrics are captured by Ansible callback plugin.

```yaml
  - name: "Create Volume in {{ availability_zone }}"
    openstack.cloud.volume:
      state: present
      availability_zone: "{{ availability_zone | default(omit) }}"
      size: 10
      display_name: "{{ volume_name }}"
    tags:
      - "metric=create_volume"
```

---
## Generic StackMon plugin

```mermaid
graph LR

  test[Test Load]
  lb[Load Balancer]
  
  subgraph cloud ["Cloud"]
    direction LR
    lb[Load Balancer]
    vm1
    vm2
    vm3
    lb -->|az1| vm1
    lb -->|az2| vm2
    lb -->|az3| vm3
  end
  
  test --> lb
```

---
## Data Flow

```mermaid
flowchart LR

  subgraph zone1
    test1["Test Load 1"]
    test2["Test Load 2"]
    statsd1
    graphite1
    test1 & test2 --> statsd1
    statsd1 --> graphite1
  end

  subgraph zone2
    test3["Test Load 3"]
    statsd2
    graphite2
    test3 --> statsd2
    statsd2 --> graphite2
  end

  subgraph env1 ["Region 1"]
    srv11
    srv12
  end
  subgraph env2["Region 2"]
    srv21
    srv22
  end
  test1 --> env1
  test2 --> env2
  test3 --> env1 & env2

  statsd2 --> graphite1
  statsd1 --> graphite2

  mp[Metric Processor]
  sdb[Status Dashboard]
  grafana[Grafana]

  graphite1 & graphite2 --> mp
  graphite1 & graphite2 --> grafana
  mp --> sdb
  mp --> grafana
```

---
## Metric Processor

When is service degraded is is experiencing outage?

- latency of GET requests is above x sec?
- POST to provision new resource fails?
- API not reachable?
- provisioned resource can not be reached anymore?
- error rate too high?
- what if things work from one zone, but not from another?

---
## Flags and Semaphores

Status definition attempt:

- outage is when `(X and Y) or Z`
- major incident is when `A and B`
- minor incident is when `A or B`

where:

- A => `bool(avg(latency) > 1s)`
- B => `bool(avg(success_rate) < 50%)`
- X => `bool(percentage(error.5XX) == 100%)`
- ...

---
## Status Dashboard

![](sdb.png)
