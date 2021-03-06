### Какой пароль у моей ВМ?

<pre>
[laboshinl@laboshinl ~]$ nova list
+--------------------------------------+------+--------+------------+-------------+---------------------------+
| ID                                   | Name | Status | Task State | Power State | Networks                  |
+--------------------------------------+------+--------+------------+-------------+---------------------------+
| b26a6faf-e5d4-4a5e-824a-9d7266970bff | win8 | ACTIVE | -          | Running     | laboshinl-net=203.0.113.4 |
+--------------------------------------+------+--------+------------+-------------+---------------------------+
[laboshinl@laboshinl ~]$ nova get-password b26a6faf-e5d4-4a5e-824a-9d7266970bff ~/.ssh/id_rsa
0jwiDgNro3oTjf
</pre>

# Создание образов операционных систем Windows

Данные скрипты предназначены для создания образов виртуальных машин семейства Windows, которые могут быть использованы для запуска виртуальных машин в облачной инфраструктуре Openstack.
Скрипты производят установку драйверов (VirtIO https://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/) и программных компонент cloud-init, включающих получение генерацию пользователя при первом запуске, автоматическое расширение файловой системы и т.д. разработанные http://www.cloudbase.it/

Инструкции приведены для операционной системы CentOS 6.5

Добавить репозиторий rpmforge (Нужен для свежего xmlstarlet)
<pre>
yum localinstall -y http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
</pre>

Установить необходимые зависимости

<pre>
yum install -y qemu-kvm git xmlstarlet dosfstools mkisofs
</pre>

Создать локальную копию репозитория со скриптами автоматизаци создания образов windows

<pre>
git clone https://github.com/laboshinl/windows-openstack-imaging-tools.git && cd windows-openstack-imaging-tools/
</pre>

Скачать необходимый установочный ISO (в примере windows 7 x86)

<pre>
curl -O http://msft.digitalrivercontent.net/win/X17-24280.iso
</pre>

Скачать виртио ISO

<pre>
./download-virtio.sh
</pre> 

 
## Windows 7,8,2008,2012
 
Сгерерировать нужный скрипт автоматизации
<pre>
./customize.sh -e 7 -f "Windows 7 ENTERPRISE" -p 32
</pre>

Возможные варианты флагов:
<pre>
-e 'vista' '7' '8' '2008' '2012'
-f 'Windows 7 ENTERPRISE' 'Windows 7 ENTERPRISEN' 'Windows 8 ENTERPRISE' 'Windows 8 PROFESSIONAL' 
   'Windows 8.1 ENTERPRISE' 'Windows 8.1 PROFESSIONAL' 'Windows Server 2008 R2 SERVERHYPERCORE' 
   'Windows Server 2008 R2 SERVERSTANDARD' 'Hyper-V Server 2012 SERVERHYPERCORE' 
   'Windows Server 2012 SERVERSTANDARD' 'Hyper-V Server 2012 R2 SERVERHYPERCORE' 
   'Windows Server 2012 R2 SERVERSTANDARD'
-p '32' '64'
</pre> 
Создать загрузочную дискету
<pre>
./create-autounattend-floppy.sh
</pre> 

Запустить установку 
<pre>
./create.sh X17-24280.iso
</pre>

## Windows xp (x86)

Вписать корректный серийный номер операционной системы в файлы Winnt.sif и xp-support/sysprep.inf:

> ProductKey=XXXXX-XXXXX-XXXXX-XXXXX-XXXXX

### Для Windows 2003 Server (x86) 

Так же заменить в файле xp-support/first.cmd 
строчку
> start /wait WindowsXP-KB968930-x86-ENG.exe /passive

на 
> start /wait WindowsServer2003-KB968930-x86-ENG.exe /passive


Создать iso с необходимыми обновлениями (KB968930, NetFx20SP1)

<pre>
./create-xp-support-iso.sh 
</pre> 
 
Создать загрузочную дискету (флаг x означает поддержку XP)
<pre>
./create-autounattend-floppy.sh -x
</pre> 

Запустить установку 
<pre>
./create-xp.sh XP.iso
</pre>


Подключиться к консоли виртуальной машины, где происходит установка операционной системы
<pre>
vncviewer [IP]:1
</pre>
На этапе выбора диска для установки укажите путь соответствующиим драйверам с диска E:/
Во время установки система будет несуолько раз перезагружена.
После завершения установки, виртуальная машина будет выключена, в папке появится образ [Имя установочного образа].qcow2
<pre>
glance image-create --is-public True --progress --name win7-i386 --container-format bare --disk-format qcow2 --human-readable < X17-24280.iso.qcow2
</pre>



