# bogus VMWare install is fun

rnddir=

while : ; do
        rnddir=$(sudo ls /tmp/ |grep modconfig)
        if [ $? -eq 0 ] ; then
                break;
        fi
done

while : ; do
        sudo ls /tmp/$rnddir/vmci-only/linux
        if [ $? -eq 0 ] ; then
                break;
        fi
done
sudo cp -v /usr/src/open-vm-tools-2012.12.26/vmci/linux/driver.c /tmp/$rnddir/vmci-only/linux/driver.c
