# 项目说明
在 Serv00 和 CT8 机器上一步到位地安装和配置 vmess+vmess&argo+socks5+哪吒探针，socks5 可用于 cmliu/edgetunnel 项目的`SOCKS5`变量实现反代，帮助解锁 ChatGPT 等服务。

通过 GitHub 自带的 action 功能，使服务器面板的 corn 定时任务保持，而 corn 则使节点进程保持活跃，从而实现节点保活。

## 项目借鉴
- 老王的四合一节点,[仓库地址](https://github.com/eooce/Sing-box)  
> 特点：一次生成多协议节点。无论单协议还是多协议，均可以通过vps或action远程登录ssh安装无交互一键脚本来保活

- CM的socks5+nezha项目，[仓库地址](https://github.com/cmliu/socks5-for-serv00)
> 特点：仅生成socks5协议，用于其edt项目的SOCKS5反打变量

----

## 本人魔改四合一脚本，适用于serv00 & ct8，含vmess|vmess+argo|hy2|socks5|nezha

- **四合一安装脚本，需要交互式输入**
```
curl -s https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/sb_serv00_socks.sh -o sb00.sh && bash sb00.sh  
```
![主菜单截图](https://fastly.jsdelivr.net/gh/yutian81/yutian81.github.io@master/assets/images/17258552404381725855239743.png)

- 也可以支持老王的无交互安装
例如：  
VMESS_PORT=tcp端口 HY2_PORT=udp端口 SOCKS_PORT=udp端口 bash <(curl -Ls https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/sb_serv00_socks.sh)

- 其他变量也可一并写入，例如：  
UUID=123456 NEZHA_SERVER=nz.abcd.com NEZHA_PORT=5555 NEZHA_KEY=123ABC ARGO_DOMAIN=2go.admin.com ARGO_AUTH=abc123

## *特别注意：ARGO_AUTH变量必须是json格式才可以通过保活重启，token格式的无法重启*

可以通过F大的API获取json：https://fscarmen.cloudflare.now.cc

----

## VPS版一键无交互脚本 5in1：vless+reality|vmess+argo|hy2|tuic|socks5
```
vless_port=自定义端口 bash <(curl -Ls https://raw.githubusercontent.com/yutian81/serv00-ct8-ssh/main/vps_sb5in1.sh)
```
----

## 关于节点保活
#### action方式保活
- [CM的博文](https://blog.cmliussss.com/p/Serv00-Socks5/#%E6%AD%A5%E9%AA%A44-%E5%BC%80%E5%90%AFGithub-Actions%E4%BF%9D%E6%B4%BB)
- CM的[视频教程](https://youtu.be/L6gPyyD3dUw)
- action变量 `ACCOUNTS_JSON` 格式示例
```json
[
  {"username": "cmliusss", "password": "7HEt(xeRxttdvgB^nCU6", "panel": "panel4.serv00.com", "ssh": "s4.serv00.com"},
  {"username": "cmliussss2018", "password": "4))@cRP%HtN8AryHlh^#", "panel": "panel7.serv00.com", "ssh": "s7.serv00.com"},
  {"username": "4r885wvl", "password": "%Mg^dDMo6yIY$dZmxWNy", "panel": "panel.ct8.pl", "ssh": "s1.ct8.pl"}
]
```

#### CF worker 方式保活
- [天诚博文教程](https://linux.do/t/topic/181957)
- [天诚相关代码](https://github.com/yutian81/serv00-ct8-ssh/tree/main/cf-sb00-alive)

#### vps远程登录ssh方式保活
- [老王相关代码及本人修改的多服务器批量保活代码](https://github.com/yutian81/serv00-ct8-ssh/tree/main/vps_sb00_alive)

----

## 仅安装哪吒agent
```
bash <(curl -s https://raw.githubusercontent.com/k0baya/nezha4serv00/main/install-agent.sh)
```

----

## 一键卸载pm2
```bash
pm2 unstartup && pm2 delete all && npm uninstall -g pm2
```
## 手动重置服务器，逐行执行
```
pkill -kill -u $(whoami)
chmod -R 755 ~/*
chmod -R 755 ~/.*
rm -rf ~/.*
rm -rf ~/*
```
