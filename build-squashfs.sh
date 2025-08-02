#!/bin/bash
function installWithAptss() {
    if [[ $isUnAptss == 1 ]]; then
        chrootCommand apt "$@"
    else
        chrootCommand aptss "$@"
    fi
}
function chrootCommand() {
    for i in {1..5};
    do
        sudo env DEBIAN_FRONTEND=noninteractive chroot $debianRootfsPath "$@"
        if [[ $? == 0 ]]; then
            break
        fi
        sleep 1
    done
}
function UNMount() {
    sudo umount "$1/sys/firmware/efi/efivars"
    sudo umount "$1/sys"
    sudo umount "$1/dev/pts"
    sudo umount "$1/dev/shm"
    sudo umount "$1/dev"

    sudo umount "$1/sys/firmware/efi/efivars"
    sudo umount "$1/sys"
    sudo umount "$1/dev/pts"
    sudo umount "$1/dev/shm"
    sudo umount "$1/dev"

    sudo umount "$1/run"
    sudo umount "$1/media"
    sudo umount "$1/proc"
    sudo umount "$1/tmp"
}
function buildDebianRootf() {
    if [[ $1 == loong64 ]]; then
        sudo debootstrap --no-check-gpg --keyring=/usr/share/keyrings/debian-ports-archive-keyring.gpg \
            --include=debian-ports-archive-keyring,debian-archive-keyring,sudo,vim \
            --arch $1 unstable $debianRootfsPath https://mirrors.nju.edu.cn/debian-ports/
        if [[ $? != 0 ]]; then
            sudo apt install squashfs-tools git aria2 -y
            aria2c -x 16 -s 16 https://repo.gxde.top/TGZ/debian-base-loong64/debian-base-loong64.squashfs
            sudo unsquashfs debian-base-loong64.squashfs
            sudo rm -rf $debianRootfsPath/
            sudo mv squashfs-root $debianRootfsPath -v
        fi
    else
        sudo debootstrap --arch $1 \
            --include=debian-ports-archive-keyring,debian-archive-keyring,sudo,vim \
            $2 $debianRootfsPath https://mirrors.cernet.edu.cn/debian/
    fi
}
programPath=$(cd $(dirname $0); pwd)
debianRootfsPath=debian-rootfs
if [[ $1 == "" ]]; then
    echo 请指定架构：i386 amd64 arm64 mips64el loong64
    echo 还可以代号以构建内测镜像
    echo "如 $0  amd64  [tianlu] [aptss(可选)] 顺序不能乱"
    exit 1
fi
if [[ -d $debianRootfsPath ]]; then
    UNMount $debianRootfsPath
    sudo rm -rf $debianRootfsPath
fi
export isUnAptss=1
if [[ $1 == aptss ]] || [[ $2 == aptss ]]|| [[ $3 == aptss ]]; then
    export isUnAptss=0
fi
sudo rm -rf grub-deb
sudo apt install debian-archive-keyring debian-ports-archive-keyring -y
sudo apt install debootstrap  \
    qemu-user-static genisoimage xorriso \
    squashfs-tools -y
# 构建核心系统
set +e
case $2 in
    "tianlu")
        buildDebianRootf $1 bookworm
        sudo cp $programPath/gxde-temp-bixie.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "bixie")
        buildDebianRootf $1 bookworm
        sudo cp $programPath/gxde-temp-bixie.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "lizhi")
        buildDebianRootf $1 trixie
        sudo cp $programPath/gxde-temp-lizhi.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "zhuangzhuang")
        buildDebianRootf $1 trixie
        sudo cp $programPath/gxde-temp-lizhi.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "meimei")
        if [[ ! -e /usr/share/debootstrap/scripts/loongnix ]]; then
            sudo cp loongnix /usr/share/debootstrap/scripts/ -v
        fi
        sudo debootstrap --no-check-gpg --arch $1 \
            --include=debian-ports-archive-keyring,debian-archive-keyring,sudo,vim \
            loongnix $debianRootfsPath https://pkg.loongnix.cn/loongnix/25
        sudo cp $programPath/gxde-temp-meimei.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
    "hetao")
        if [[ ! -e /usr/share/debootstrap/scripts/loongnix ]]; then
                sudo cp crimson /usr/share/debootstrap/scripts/ -v
        fi
        sudo debootstrap --no-check-gpg --arch $1 \
            --include=deepin-keyring,sudo,vim \
            crimson $debianRootfsPath https://mirrors.hit.edu.cn/deepin/beige/
        sudo cp $programPath/gxde-temp-hetao.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
        sudo sed -i "s/main/main commercial community/g" $debianRootfsPath/etc/apt/sources.list
    ;;
    *)
        buildDebianRootf $1 bookworm
        sudo cp $programPath/gxde-temp-bixie.list $debianRootfsPath/etc/apt/sources.list.d/temp.list -v
    ;;
esac

# 修改系统主机名
echo "gxde-os" | sudo tee $debianRootfsPath/etc/hostname
# 写入源
if [[ $2 == "" ]] || [[ $2 == "tianlu" ]] || [[ $2 == "bixie" ]]; then
    if [[ $1 == loong64 ]]; then
        sudo cp $programPath/debian-unreleased.list $debianRootfsPath/etc/apt/sources.list -v
    else
        sudo cp $programPath/debian.list $debianRootfsPath/etc/apt/sources.list -v
        #sudo cp $programPath/debian-backports.list $debianRootfsPath/etc/apt/sources.list.d/debian-backports.list -v
        sudo cp $programPath/99bookworm-backports $debianRootfsPath/etc/apt/preferences.d/ -v
    fi
fi
#sudo cp $programPath/os-release $debianRootfsPath/usr/lib/os-release
if [[ $2 != "hetao" ]]; then
    sudo sed -i "s/main/main contrib non-free non-free-firmware/g" $debianRootfsPath/etc/apt/sources.list
fi


set +e
# 安装应用

sudo $programPath/pardus-chroot $debianRootfsPath
chrootCommand apt update -o Acquire::Check-Valid-Until=false
chrootCommand apt install debian-ports-archive-keyring debian-archive-keyring -y
chrootCommand apt install sudo vim -y
chrootCommand apt install gxde-source -y
chrootCommand rm -rfv /etc/apt/sources.list.d/temp.list
chrootCommand apt update -o Acquire::Check-Valid-Until=false
if [[ $2 == "tianlu" ]] || [[ $2 == "zhuangzhuang" ]]; then
    chrootCommand apt install gxde-testing-source -y
    chrootCommand apt update -o Acquire::Check-Valid-Until=false
fi
chrootCommand apt install aptss -y
chrootCommand aptss update -o Acquire::Check-Valid-Until=false


# 
installWithAptss install gxde-desktop --install-recommends -y
# 启用 lightdm
chrootCommand systemctl enable lightdm
chrootCommand dpkg-reconfigure gxde-session-ui
if [[ $1 != "mips64el" ]]; then
	installWithAptss install calamares-settings-gxde --install-recommends -y
else
	installWithAptss install calamares-settings-gxde-mips64el --install-recommends -y
fi
if [[ $2 == "hetao" ]]; then
    # 安装该包以正常运行 dtk6 应用
    installWithAptss install dde-qt6integration dde-qt6xcb-plugin --install-recommends -y
fi
#else
#    installWithAptss install gxde-installer --install-recommends -y
#fi

sudo rm -rf $debianRootfsPath/var/lib/dpkg/info/plymouth-theme-gxde-logo.postinst
installWithAptss install live-task-recommended live-task-standard live-config-systemd \
    live-boot -y
installWithAptss install  fcitx5-frontend-all fcitx5-pinyin fcitx5-chinese-addons libime-bin libudisks2-qt5-0 fcitx5 -y
# 

installWithAptss update -o Acquire::Check-Valid-Until=false

installWithAptss full-upgrade -y

installWithAptss install linglong-bin linglong-box -y

if [[ $1 == loong64 ]]; then
    chrootCommand aptss install spark-store -y
    chrootCommand aptss update -o Acquire::Check-Valid-Until=false
    chrootCommand aptss install cn.loongnix.lbrowser -y
elif [[ $1 == amd64 ]]; then
    chrootCommand aptss install spark-store -y
    chrootCommand aptss update -o Acquire::Check-Valid-Until=false
    chrootCommand aptss install firefox-spark -y
    chrootCommand aptss install spark-deepin-cloud-print spark-deepin-cloud-scanner -y
    installWithAptss install dummyapp-wps-office dummyapp-spark-deepin-wine-runner -y
    if [[ $2 != "hetao" ]]; then
        installWithAptss install boot-repair -y
    fi
elif [[ $1 == arm64 ]]; then
    chrootCommand aptss install spark-store -y
    chrootCommand aptss update -o Acquire::Check-Valid-Until=false
    chrootCommand aptss install firefox-spark -y
    installWithAptss install dummyapp-wps-office dummyapp-spark-deepin-wine-runner -y
elif [[ $1 == "mips64el" ]]; then
    chrootCommand apt install loongsonapplication -y
    installWithAptss install firefox-esr firefox-esr-l10n-zh-cn -y
elif [[ $1 == "i386" ]]; then
    chrootCommand apt install aptss -y
    installWithAptss update -o Acquire::Check-Valid-Until=false
    installWithAptss install firefox-esr firefox-esr-l10n-zh-cn -y
    installWithAptss install dummyapp-spark-deepin-wine-runner boot-repair -y
else 
    chrootCommand apt install aptss -y
    installWithAptss update -o Acquire::Check-Valid-Until=false
    installWithAptss install firefox-esr firefox-esr-l10n-zh-cn -y
fi
#if [[ $1 == arm64 ]] || [[ $1 == loong64 ]]; then
#    installWithAptss install spark-box64 -y
#fi
#chrootCommand apt install grub-efi-$1 -y
#if [[ $1 != amd64 ]]; then
#    chrootCommand apt install grub-efi-$1 -y
#fi
# 卸载无用应用
installWithAptss purge  mlterm mlterm-tiny deepin-terminal-gtk deepin-terminal ibus systemsettings deepin-wine8-stable breeze-* -y
# 安装内核
if [[ $1 != amd64 ]]; then
    installWithAptss autopurge "linux-image-*" "linux-headers-*" -y
fi
installWithAptss install linux-kernel-gxde-$1 -y
# 如果为 amd64/i386 则同时安装 oldstable 内核
if [[ $1 == amd64 ]] || [[ $1 == i386 ]] || [[ $1 == mips64el ]]; then
    installWithAptss install linux-kernel-oldstable-gxde-$1 -y
fi
if [[ $2 == hetao ]]; then
    # 安装 HWE 内核
    installWithAptss install linux-kernel-hwe-gxde-$1 -y
else
    if [[ $1 == arm64 ]]; then
        installWithAptss install linux-kernel-phytium-gxde-arm64 -y
    fi
fi

# 禁用 nmbd
chrootCommand systemctl disable nmbd
if [[ $2 == hetao ]]; then
    installWithAptss install linux-firmware -y
    if [[ $1 == loong64 ]]; then
        # 安装 loong gpu 驱动
        installWithAptss install loonggpu-driver -y
    fi
else
    installWithAptss install firmware-linux -y
fi
installWithAptss install firmware-iwlwifi firmware-realtek -y
installWithAptss install firmware-sof-signed -y
installWithAptss install grub-common -y
# 清空临时文件
installWithAptss autopurge fonts-noto-extra fonts-noto-ui-extra fonts-noto-cjk-extra -y
installWithAptss autopurge -y
installWithAptss clean
# 下载所需的安装包
chrootCommand apt install grub-pc --download-only -y
chrootCommand apt install grub-efi-$1 --download-only -y
chrootCommand apt install grub-efi --download-only -y
chrootCommand apt install grub-common --download-only -y
chrootCommand apt install cryptsetup-initramfs cryptsetup keyutils --download-only -y


mkdir grub-deb
sudo cp $debianRootfsPath/var/cache/apt/archives/*.deb grub-deb
# 清空临时文件
installWithAptss clean
sudo touch $debianRootfsPath/etc/deepin/calamares
sudo rm $debianRootfsPath/etc/apt/sources.list.d/debian.list -rf
sudo rm $debianRootfsPath/etc/apt/sources.list.d/debian-backports.list -rf
sudo rm -rf $debianRootfsPath/var/log/*
sudo rm -rf $debianRootfsPath/root/.bash_history
sudo rm -rf $debianRootfsPath/etc/apt/sources.list.d/temp.list
sudo rm -rf $debianRootfsPath/initrd.img.old
sudo rm -rf $debianRootfsPath/vmlinuz.old
# 卸载文件
sleep 5
UNMount $debianRootfsPath
# 封装
cd $debianRootfsPath
set -e
sudo rm -rf ../filesystem.squashfs
sudo mksquashfs * ../filesystem.squashfs
cd ..
#du -h filesystem.squashfs
# 构建 ISO
if [[ ! -f iso-template/$1-build.sh ]]; then
    echo 不存在 $1 架构的构建模板，不进行构建
    exit
fi
cd iso-template/$1
# 清空废弃文件
rm -rfv live/*
rm -rfv deb/*/
mkdir -p live
mkdir -p deb
# 添加 deb 包
cd deb
./addmore.py ../../../grub-deb/*.deb
cd ..
# 拷贝内核
# 获取内核数量
kernelNumber=$(ls -1 ../../$debianRootfsPath/boot/vmlinuz-* | wc -l)
vmlinuzList=($(ls -1 ../../$debianRootfsPath/boot/vmlinuz-* | sort -rV))
initrdList=($(ls -1 ../../$debianRootfsPath/boot/initrd.img-* | sort -rV))
for i in $( seq 0 $(expr $kernelNumber - 1) )
do
    if [[ $i == 0 ]]; then
        cp ../../$debianRootfsPath/boot/${vmlinuzList[i]} live/vmlinuz -v
        cp ../../$debianRootfsPath/boot/${initrdList[i]} live/initrd.img -v
    fi
    if [[ $i == 1 ]]; then
        cp ../../$debianRootfsPath/boot/${vmlinuzList[i]} live/vmlinuz-oldstable -v
        cp ../../$debianRootfsPath/boot/${initrdList[i]} live/initrd.img-oldstable -v
    fi
done
if [[ ! -f live/initrd.img-oldstable ]] ;then
    cp live/initrd.img live/initrd.img-oldstable
fi
if [[ ! -f live/vmlinuz-oldstable ]] ;then
    cp live/vmlinuz live/vmlinuz-oldstable
fi
sudo mv ../../filesystem.squashfs live/filesystem.squashfs -v
cd ..
bash $1-build.sh
mv gxde.iso ..
cd ..
du -h gxde.iso
