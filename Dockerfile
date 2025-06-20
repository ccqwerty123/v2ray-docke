# Dockerfile (v4 - 修复版，采用多阶段构建)

# --- 阶段1: 构建器 (Builder) ---
# 使用一个临时的镜像，专门用于下载和解压
FROM alpine:3.20 AS builder

# 在这个阶段安装我们需要的构建工具
RUN apk add --no-cache wget unzip

# 设置工作目录并下载 V2Ray
WORKDIR /tmp
RUN wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -O v2ray.zip

# 将 zip 文件解压到一个临时目录中
# 这种分步操作比直接解压到 /usr/bin/ 更稳定，可以规避段错误
RUN unzip v2ray.zip -d /v2ray-build


# --- 阶段2: 最终镜像 (Final Image) ---
# 使用一个全新的、纯净的 alpine 镜像开始
FROM alpine:3.20

# 运行时需要 wget 来支持从 URL 获取域名
RUN apk add --no-cache wget

# 从第一阶段 (builder) 精准地复制我们需要的最终文件
# 只拷贝 v2ray 和 v2ctl 这两个可执行程序
COPY --from=builder /v2ray-build/v2ray /usr/bin/
COPY --from=builder /v2ray-build/v2ctl /usr/bin/
# 确保文件有可执行权限
RUN chmod +x /usr/bin/v2ray /usr/bin/v2ctl

# 设置工作目录并复制我们自己的配置文件和脚本
WORKDIR /etc/v2ray
COPY config.template.json .
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# 暴露端口并定义入口点
EXPOSE 443
ENTRYPOINT ["/entrypoint.sh"]
