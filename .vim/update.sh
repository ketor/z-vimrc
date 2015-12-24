update_cmd="proxychains4 git pull"
$update_cmd
cd autoload
$update_cmd;cd ..
cd bundle
for i in `ls`; do cd $i;$update_cmd;cd ..; done
cd ..

