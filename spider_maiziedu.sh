#!/bin/bash
#$1 like this: http://www.maiziedu.com/course/9/

#update:2017-09-23 修复文件保存错误问题

CourseURL=$1
ClassID=`echo $CourseURL | awk -F \/ '{print $5}'`
WgetFile=file1
DutyList=file2
wget $CourseURL -O $WgetFile 2>&1 | >/dev/null
CourseName=`cat $WgetFile  | grep h1 | awk -F \> '{print $2}'| awk -F \< '{print $1}' | sed 's/[ ][ ]*//g'|sed 's/\t//g' `
cat $WgetFile|grep -E "<li><a href=\"/course/$ClassID"|awk -F \" '{print $2"@"$9}'|sed -r s/\(\>\|\<.*\)//g|sed s/$/.mp4/g|sed 's/[ ][ ]*//g'|sed 's/\t//g' >$DutyList
mkdir $CourseName 2>&1 | > /dev/null
seq=0;
for line in `cat $DutyList`
do
    let seq+=1
    url='http://www.maiziedu.com'`echo $line | awk -F @ '{print $1}'`

    if [ $seq -le 9 ]
    then
        filename=0`echo $line | awk -F @ '{print $2}' `
    else
        filename=`echo $line | awk -F @ '{print $2}' `
    fi

    realsource=`curl $url  2>&1 | grep lessonUrl 2>&1 | awk -F \" '{print $2}'`
    echo -e "\033[32;38m正在从[$realsource]下载[$filename],保存到[$CourseName]目录.\033[0m"
    rm -rf  $CourseName/$filename
    wget $realsource -O $CourseName/$filename
done
