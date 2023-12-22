# Nomad Consul Vault Development

## Background

Developing on a local environment and a cloud environment can often be a challenging task. One of the pain points is the need to ensure that our services run smoothly in both environments. To achieve this, we often have to connect the surrounding isolated services to test our code and ensure its proper functionality. This process can be time-consuming and complex, as it requires setting up and configuring the necessary dependencies and infrastructure to mimic the cloud environment locally. However, it is crucial to perform these tests to identify and fix any issues before deploying our code to the cloud environment, ensuring a seamless transition and a reliable service for end-users.

## Hashicorp Nomad, Consul and Vault

Hashicorp Nomad is a cluster manager and scheduler that allows us to deploy applications and services on a cluster of machines. It is a lightweight and flexible tool that can be used to deploy containerized and non-containerized applications. It is also cloud-agnostic, which means that it can be used to deploy applications on any cloud provider or on-premise data center. Nomad is also highly available and fault-tolerant, which means that it can tolerate failures and continue to operate without any downtime. It also supports multi-datacenter deployments, which means that we can deploy applications across multiple data centers and regions.

<!-- insert nomad logo -->
![Nomad Logo](https://cdn.freebiesupply.com/logos/large/2x/nomad-2-logo-png-transparent.png)



Hashicorp Consul is a service mesh that provides service discovery, configuration, and segmentation functionality. It is a distributed system that can be used to connect and secure services across any runtime platform and public or private cloud. Consul is also highly available and fault-tolerant, which means that it can tolerate failures and continue to operate without any downtime. It also supports multi-datacenter deployments, which means that we can deploy applications across multiple data centers and regions.

<!-- insert consul logo -->
![Consul Logo](https://www.vectorlogo.zone/logos/consulio/consulio-ar21.png)

Hashicorp Vault is a secrets management tool that allows us to store and access sensitive data such as passwords, API keys, and certificates. It is a distributed system that can be used to secure, store, and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API. Vault is also highly available and fault-tolerant, which means that it can tolerate failures and continue to operate without any downtime. It also supports multi-datacenter deployments, which means that we can deploy applications across multiple data centers and regions.

<!-- insert vault logo -->
![Vault Logo](https://www.vectorlogo.zone/logos/vaultproject/vaultproject-ar21.png)

## Developing with nomad, consul and vault

When developing applications, it is essential to ensure that they can run smoothly in both local and cloud environments. This often involves connecting isolated services to test code functionality. However, setting up and configuring the necessary dependencies and infrastructure to mimic the cloud environment locally can be time-consuming and complex.

Fortunately, HashiCorp provides three powerful tools - Nomad, Consul, and Vault - that can be seamlessly integrated to facilitate development in a local environment. Nomad is a cluster manager and scheduler that allows for the deployment of applications and services on a cluster of machines. Consul, on the other hand, is a service mesh that provides service discovery, configuration, and segmentation functionality. Lastly, Vault is a secrets management tool that securely stores and controls access to sensitive data.

By leveraging these tools together, developers can easily deploy and manage applications on their local machines, mimicking the behavior of a cloud environment. This integration allows for efficient testing and debugging, ensuring a seamless transition when deploying code to the cloud environment. With Nomad, Consul, and Vault, developers can confidently develop and test their applications locally, knowing that they will run smoothly in the cloud.

## Installation

first, you need to install the following tools:

Nomad

```bash
# Download Nomad Linux
sudo apt-get update && \
sudo apt-get install wget gpg coreutils && \
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && \
sudo apt-get update && \
sudo apt-get install nomad
```

Post installation, we must instal the CNI plugins and enable the bridge-nf-call-iptables kernel module. This is required for Nomad to properly configure the network for containers.

explain:

The selected text from the `README.md` file is providing instructions for post-installation steps required for Nomad, a workload orchestrator, to properly configure the network for containers.

Firstly, it mentions the need to install the Container Network Interface (CNI) plugins. CNI is a standard that defines how network interfaces for Linux containers should be configured and managed. CNI plugins are used by container runtimes, like Docker and Podman, to set up networking for containers. They allow different networking solutions to be used with containers and are crucial for enabling communication between containers, and between containers and the outside world.

Secondly, the text instructs to enable the `bridge-nf-call-iptables` kernel module. This is a Linux kernel option that allows iptables rules to be applied to traffic coming in and out of a network bridge, such as the one Docker uses to connect containers to the host system. Enabling this option is necessary for certain network operations, like Network Address Translation (NAT), to work correctly with containers. This is particularly important for orchestrators like Nomad, which need to manage and route network traffic for containers efficiently and securely.

```bash
# Post installation
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz && \
    sudo mkdir -p /opt/cni/bin && \
    sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-arptables && \
    echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-ip6tables && \
    echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

sudo sysctl -w net.bridge.bridge-nf-call-arptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
```

Consul

Since we already intall hashicorp repo on the previous step, we can install consul with the following command:

```bash
sudo apt-get install consul
```

Vault

```bash
sudo apt-get install vault
```

## Configurations

### Nomad

To enable Nomad to join and integrate with Consul and Vault, we need to provide some configuration options. Let's take a closer look at the relevant lines of code:

```hcl
datacenter = "dc1"
client {
    enabled = true
    servers = ["localhost:4647"]
    options {
        "consul.auto_join" = "provider=local"
        "consul.datacenter" = "dc1"
        "consul.retry_join" = ["localhost:4646"]
        "consul.retry_interval" = "5s"
    }
}
vault {
    enabled = true
    address = "http://127.0.0.1:8200"
    # Only needed in servers when transioning from the token-based flow to
    # workload identities.
    create_from_role = "nomad-cluster"
    # Provide a default workload identity configuration so jobs don't need to
    # specify one.
    default_identity {
        aud  = ["vault.io"]
        env  = false
        file = true
        ttl  = "1h"
    }
}
server {
    enabled = true
    bootstrap_expect = 1
    retry_join = ["localhost:4646"]
}
ui {
    enabled = true
}
consul {
    address = "localhost:8500"
}
```

In this configuration block, we have specified that the Nomad client is enabled (enabled = true) and provided the address of the Consul server (servers = ["localhost:4647"]). Additionally, we have a nested options block where we can set specific configuration options for Consul.

The following options are set for Consul integration:

"consul.auto_join" = "provider=local": This option tells Nomad to automatically join the Consul cluster using the local provider. This means that Nomad will attempt to join the Consul cluster running on the same machine.
"consul.datacenter" = "dc1": Specifies the name of the Consul datacenter that Nomad should join. In this case, it is set to "dc1".
"consul.retry_join" = ["localhost:4646"]: Specifies the addresses of the Consul servers that Nomad should attempt to join. In this example, it is set to ["localhost:4646"], indicating that Nomad should try to join the Consul server running on localhost at port 4646.
"consul.retry_interval" = "5s": Specifies the interval at which Nomad should retry joining the Consul cluster if the initial join attempt fails. In this case, it is set to "5s", indicating a retry interval of 5 seconds.


### Consul

```hcl
datacenter = "dc1"
data_dir = "./consul/tmp/data"
log_level = "DEBUG"
server = true
ui_config {
    enabled = true
}
ui = true
advertise_addr = "127.0.0.1"
```

### Vault

The code snippet provided shows the configuration for using Consul as the database backend for Vault.

```hcl
storage "consul" {
    address = "127.0.0.1:8500"
    path    = "vault/"
}


ui = true
```

## Running the cluster

To run the cluster, we need to run the following commands:

```bash
./install.sh
```

## Result

Consul is up and running locally, and Nomad has been successfully integrated. The configuration files provided in the code snippets demonstrate the setup of both Consul and Nomad. Consul is configured with the datacenter set to "dc1" and the server mode enabled. Nomad is configured to join the Consul cluster using the local provider and specified Consul servers. With these configurations in place, Consul and Nomad are ready to work together seamlessly.

Nomad is up and running locally, as indicated by the successful execution of the ./install.sh command. The configuration options provided in the code snippets ensure that Nomad is integrated with Consul and Vault, allowing for seamless coordination and management of distributed applications

Vault is up and running locally with the backend successfully connected to Consul. This integration allows Vault to securely store and manage secrets. To access the Vault UI, you can use the root token generated below using the CLI command. The Vault UI provides a user-friendly interface to interact with Vault and manage secrets effectively.

## Conclusion

In this article, we have explored how Nomad, Consul, and Vault can be seamlessly integrated to facilitate development in a local environment. We have also discussed the benefits of using these tools together and how they can be leveraged to ensure a seamless transition when deploying code to the cloud environment. With Nomad, Consul, and Vault, developers can confidently develop and test their applications locally, knowing that they will run smoothly in the cloud.

## References

- [Hashicorp Nomad](https://www.nomadproject.io/)
- [Hashicorp Consul](https://www.consul.io/)
- [Hashicorp Vault](https://www.vaultproject.io/)