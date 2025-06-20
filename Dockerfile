# Dockerfile (最终修复版 v5)

# --- 阶段1: 构建器 (Builder) ---
# 使用一个临时的镜像，专门用于下载和解压
FROM alpine:3.20 AS builder

# 在这个阶段安装我们需要的构建工具
RUN apk add --no-cache wget unzip

# 设置工作目录并下载 V2Ray
WORKDIR /tmp
RUN wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -O v2ray.zip

# 将 zip 文件解压到一个临时目录中
RUN unzip v2ray.zip -d /v2ray-build


# --- 阶段2: 最终镜像 (Final Image) ---
# 使用一个全新的、纯净的 alpine 镜像开始
FROM alpine:3.20

# 运行时需要 wget 来支持从 URL 获取域名
RUN apk add --no-cache wget

# 从第一阶段 (builder) 只复制我们唯一需要的 v2ray 程序
COPY --from=builder /v2ray-build/v2ray /usr/bin/
# (已移除对 v2ctl 的复制，因为它已不存在)

# 确保 v2ray 文件有可执行权限
RUN chmod +x /usr/bin/v2ray
# (已移除对 v2ctl 的权限设置)

# 设置工作目录并复制我们自己的配置文件和脚本
WORKDIR /etc/v2ray
COPY config.template.json .
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# 暴露端口并定义入口点
EXPOSE 443
ENTRYPOINT ["/entrypoint.sh"]
