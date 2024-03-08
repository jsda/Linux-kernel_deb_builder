#!/usr/bin/env bash

python3 get-newest-version.py 0
python3 get-newest-version.py 1
python3 get-newest-version.py 2
mainline=`cat /tmp/mainline.txt`
mainlineurl=`cat /tmp/mainlineurl.txt`
MAINVERSION=`expr substr mainline 1 1`
SHOWVERSION=mainline

# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

pip3 install requests wget ttkthemes

sudo apt build-dep -y linux
neofetch



stable=`cat /tmp/stable.txt`

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

stableurl=`cat /tmp/stableurl.txt`

wget -q $stableurl    
if [[ -f linux-"$stable".tar.xz ]]; then
    tar -xvf linux-"$stable".tar.xz
fi
if [[ -f linux-"$stable".tar.gz ]]; then
    tar -xvf linux-"$stable".tar.gz
fi
if [[ -f linux-"$stable".tar ]]; then
    tar -xvf linux-"$stable".tar
fi
if [[ -f linux-"$stable".bz2 ]]; then
    tar -xvf linux-"$stable".tar.bz2
fi
cd linux-"$stable" || exit

echo -e "$(uname -r)" >> $GITHUB_STEP_SUMMARY
echo -e "当前流程工作路径：$PATH" >> $GITHUB_STEP_SUMMARY

# copy config file
cp ../config-x/mobian/sdm845.config .config

#利用scripts/config对内核进行修改，之后需要写个注释对上述提到的所以东西进行讲解
scripts/config --set-val CONFIG_BPF y
scripts/config --set-val CONFIG_BPF_EVENTS y
scripts/config --set-val CONFIG_BPF_JIT y
scripts/config --set-val CONFIG_BPF_STREAM_PARSER y
scripts/config --set-val CONFIG_BPF_SYSCALL y
scripts/config --set-val CONFIG_CGROUPS y
scripts/config --set-val CONFIG_DEBUG_INFO y
scripts/config --set-val CONFIG_DEBUG_INFO_BTF y
scripts/config --set-val CONFIG_DEBUG_INFO_REDUCED n
scripts/config --set-val CONFIG_IPV6_SEG6_BPF y
scripts/config --set-val CONFIG_KPROBE_EVENTS y
scripts/config --set-val CONFIG_KPROBES y
scripts/config --set-val CONFIG_NET_CLS_ACT y
scripts/config --set-val CONFIG_NET_CLS_BPF y
scripts/config --set-val CONFIG_NET_EGRESS y
scripts/config --set-val CONFIG_NET_INGRESS y
scripts/config --set-val CONFIG_NET_SCH_INGRESS m
scripts/config --set-val CONFIG_XDP_SOCKETS y
# 开启bbr
scripts/config --set-val CONFIG_TCP_CONG_BBR y
# scripts/config --set-str CONFIG_DEFAULT_TCP_CONG "bbr"
# 加密算法
scripts/config --set-val CONFIG_CRYPTO_CHACHA20 y
scripts/config --set-val CONFIG_CRYPTO_CHACHA20POLY1305 y

# build deb packages
sudo make olddefconfig
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
sudo make ARCH="arm64" CROSS_COMPILE="aarch64-linux-gnu-" bindeb-pkg -j"$CPU_CORES"

# move deb packages to artifact dir
cd ..

mkdir "artifact"

echo -e "当前流程工作路径：$PWD" >> $GITHUB_STEP_SUMMARY
echo -e "当前流程目录列表：\n$(ls -hl)" >> $GITHUB_STEP_SUMMARY

rm -rfv *dbg*.pkg

#mv ./* ../artifact/
mv ./*.deb artifact/
sudo bash Install-deb.sh