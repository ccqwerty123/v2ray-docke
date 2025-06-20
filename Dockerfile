# Dockerfile (最终完美版 v6 - 使用 Xray-core)

# --- 阶段1: 构建器 (Builder) ---
# 使用一个临时的镜像，专门用于下载和解压
FROM alpine:3.20 AS builder

# 在这个阶段安装我们需要的构建工具
RUN apk add --no-cache wget unzip

# 设置工作目录并下载 Xray-core (这是关键变化)
WORKDIR /tmp
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -O xray.zip

# 将 zip 文件解压到一个临时目录中
RUN unzip xray.zip -d /xray-build


# --- 阶段2: 最终镜像 (Final Image) ---
# 使用一个全新的、纯净的 alpine 镜像开始
FROM alpine:3.20

# 运行时需要 wget 来支持从 URL 获取域名
RUN apk add --no-cache wget

# 从第一阶段 (builder) 复制我们需要的 xray 主程序
COPY --from=builder /xray-build/xray /usr/bin/

# 确保 xray 文件有可执行权限
RUN chmod +x /usr/bin/xray

# 设置工作目录并复制我们自己的配置文件和脚本
WORKDIR /etc/v2ray
COPY config.template.json .
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# 暴露端口并定义入口点
EXPOSE 443
ENTRYPOINT ["/entrypoint.sh"]
