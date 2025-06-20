# Dockerfile (最终版)

# 步骤 1: 选择一个稳定且极小的官方基础镜像
# Alpine Linux 是业界公认的最小、最安全的 Docker 基础镜像之一
FROM alpine:3.20

# 步骤 2: 安装 V2Ray 核心程序和运行时依赖 (wget)，并清理构建时依赖 (unzip)
# - 使用 `&&` 将多个命令合并为一层，减小镜像体积
# - 在命令结尾处清理所有临时文件和包缓存
# - 直接从官方 GitHub Releases 下载，确保来源可靠
RUN apk add --no-cache wget unzip && \
    wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -O /tmp/v2ray.zip && \
    unzip /tmp/v2ray.zip -d /usr/bin/ v2ray v2ctl && \
    chmod +x /usr/bin/v2ray /usr/bin/v2ctl && \
    rm /tmp/v2ray.zip && \
    apk del unzip

# 步骤 3: 设置工作目录并复制必要文件
WORKDIR /etc/v2ray
COPY config.template.json .
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# 步骤 4: 暴露端口并定义入口点
# 这是 VLESS + REALITY 的标准端口
EXPOSE 443

# 定义容器启动时执行的命令。这是在容器平台运行的最佳实践。
ENTRYPOINT ["/entrypoint.sh"]
