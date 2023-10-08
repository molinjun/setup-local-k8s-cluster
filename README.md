# 搭建本地 Kubernetes 集群 
本仓库将介绍如何使用 vagrant、virtualbox、kubeadmin 搭建一个本地的 kubernetes 集群。

## 依赖
确保本地主机已经安装 [Vagrant](https://developer.hashicorp.com/vagrant/downloads) 和 [VirtualBox](https://www.virtualbox.org/wiki/Downloads)。

```bash
$ vagrant version
Installed Version: 2.3.7
Latest Version: 2.3.7

$ virtualbox --help
Oracle VM VirtualBox VM Selector v7.0.8
Copyright (C) 2005-2023 Oracle and/or its affiliates
```

## 创建集群
拉取本仓库，并直接 vagrant up 启动集群。
```bash
$ git clone git@github.com:molinjun/setup-local-k8s-cluster.git
$ cd  setup-local-k8s-cluster
$ vagrant up
```
修改配置，根据 kubernetes 版本，确认[相关依赖的版本](https://github.com/kubernetes/kubernetes/blob/release-1.22/build/dependencies.yaml)。然后修改 `settings.yaml` 文件中的相关配置。

## 本地访问集群
将集群配置复制到 `$HOME/.kube` 目录。
```
$ cp configs/config ~/.kube/
```
查看 node 状态。
```bash
$  kubectl get nodes -owide -w
```
当所有节点状态为 Ready 的时候，集群创建成功。

## 验证
部署一个 nginx 应用验证。
```
$ kubectl apply -f example/nginx-deployment.yaml 
```
浏览器访问 `<pod 所在node节点 ip>:30080` 即可看到 nginx 欢迎页面。 

## 删除集群
使用下面的指令删除集群。
```bash
$ vagrant destroy -f
```
## 参考
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/
- https://devopscube.com/kubernetes-cluster-vagrant/
- https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544
- https://ugurakgul.medium.com/creating-a-local-kubernetes-cluster-with-vagrant-ba591ab70ee2
- https://github.com/kubernetes/kubernetes/blob/master/build/dependencies.yaml