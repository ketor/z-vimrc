cd ..
backup_date=`date +%Y%m%d`
echo $backup_date
tar -czvf simple$backup_date.tar.gz .vimrc .vim/
tar --exclude .git -czvf simple$backup_date-thin.tar.gz .vimrc .vim/
cd .vim
echo "Backup Finished "$backup_date

